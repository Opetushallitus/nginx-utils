-- lua does not include set, create a dictionary
function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

function get_cookies()
  local cookies = ngx.header["Set-Cookie"] or {}
  if type(cookies) == "string" then
    cookies = {cookies}
  end
  return cookies
end
 
function add_cookie(cookie)
  local cookies = get_cookies()
  table.insert(cookies, cookie)
  ngx.header['Set-Cookie'] = cookies
end

function parse_domain(host)
  return string.match(host or "www.opintopolku.fi" , "[%w%.]*%.(%w+%.%w+)") or host
end

function random_str(len)
  local urand = assert (io.open ('/dev/urandom', 'rb'))
  local rand  = urand or assert (io.open ('/dev/random', 'rb'))
  local s = rand:read(len)
  local n = ""

  rand:close()
  for i = 1, s:len() do
    n = n .. string.format("%x", s:byte(i))
  end

  return n
end

local block = false
local errors = {}

-- Double submit protection for CSRF:
-- CSRF cookie and X-CSRF must exist andhave same content for "POST", "PUT", "DELETE", "PATCH"
local safe_http_verbs = Set {"GET", "HEAD", "OPTIONS"}
if not safe_http_verbs[ngx.var.request_method] then
  if ngx.var.cookie_csrf == nil or ngx.var.http_x_csrf == nil then
      if ngx.var.cookie_csrf == nil then
        block = true
        table.insert(errors, "NO-CSRF-COOKIE")
      end
      if ngx.var.http_x_csrf == nil then
        block = true
        table.insert(errors, "NO-CSRF-HEADER")
      end 
  elseif not (ngx.var.cookie_csrf == ngx.var.http_x_csrf) then
    block = true
    table.insert(errors, "CSRF-MISMATCH") 
  end

  ---[[
  -- clientSubSystemCode check
  if ngx.var.http_clientsubsystemcode == nil then
    table.insert(errors, "NO-CLIENTSUBSYSTEMCODE")
  end
  --]]
end

if ngx.var.http_caller_id then
  table.insert(errors, "CALLER-ID")
end

-- add CSRF cookie to response
local csrf = ngx.var.cookie_csrf
if csrf == nil then
  csrf = random_str(16)
  add_cookie("CSRF=" .. csrf .."; Secure; Path=/; Domain=" .. parse_domain(ngx.var.host))
end

-- create request header "id" from existing request id or csrf and add random string
local id = ( ngx.var.http_id or csrf ) .. ";" .. random_str(16)
ngx.req.set_header("ID", id)

-- log if errors
if next(errors) then
  local txt = 'ERROR: "' .. table.concat(errors, "|") .. '"'
  if ngx.var.http_caller_id then
    txt = txt .. ' caller-id: "' .. ngx.var.http_caller_id .. '"'
  end
  if ngx.var.http_clientsubsystemcode then
    txt = txt .. ' clientSubSystemCode: "' .. ngx.var.http_clientsubsystemcode .. '"'
  end
  txt = txt .. ' id: "' .. id .. '"'
  ngx.log(ngx.ERR, txt)
end

--[[
-- if blocking, return error string in plain text or json and return error code
if block then
  local error = "Invalid request, please read http://oph.fi"
  -- nginx.say sets status to 200 if it has not been set before
  ngx.status = ngx.HTTP_FORBIDDEN
  if ngx.var.http_accept and string.find(ngx.var.http_accept, 'application/json') then
    ngx.header.content_type = "application/json; charset=utf-8"  
    ngx.say("{'error': '", error, "'}")
  else
    ngx.say("Error: ", error)   
  end
  ngx.exit(ngx.HTTP_FORBIDDEN)
end
--]]
