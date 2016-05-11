local ophcommon = {}

function initRandomSeed()
  local urand = assert (io.open ('/dev/urandom', 'rb'))
  local rand  = urand or assert (io.open ('/dev/random', 'rb'))
  local a,b,c,d = rand:read(4):byte(1,4);
  local seed = a*0x1000000 + b*0x10000 + c *0x100 + d;
  math.randomseed(seed);
end

initRandomSeed()

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
  local n = ""
  for i = 1, len do
    n = n .. string.format("%02x", math.random(0,255))
  end
  return n
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function resolve_post_param(name)
  ngx.req.read_body()
  local args, err = ngx.req.get_post_args()
  if args then
    return args[name]
  end
end

function ophcommon.filter(blockForMinorErrors)
  local block = false
  local errors = {}
  local criticalError = false

  -- Double submit protection for CSRF:
  -- CSRF cookie and CSRF header or POST param or must exist andh ave same content for "POST", "PUT", "DELETE", "PATCH"
  local safe_http_verbs = Set {"GET", "HEAD", "OPTIONS"}
  if not safe_http_verbs[ngx.var.request_method] then
    local csrf_parameter = ngx.var.http_csrf or resolve_post_param("CSRF")
    local csrf_cookie = ngx.var.cookie_csrf
    if csrf_cookie == nil or csrf_parameter == nil then
        if csrf_cookie == nil then
          block = true
          table.insert(errors, "NO-CSRF-COOKIE")
        end
        if csrf_parameter == nil then
          block = true
          table.insert(errors, "NO-CSRF-PARAM")
        end 
    elseif not (csrf_cookie == csrf_parameter) then
      block = true
      table.insert(errors, "CSRF-MISMATCH") 
    end
  end

  -- clientSubSystemCode check
  local clientSubSystemCode = ngx.var.http_clientsubsystemcode or ngx.var.http_caller_id
  if clientSubSystemCode == nil then
    clientSubSystemCode = resolve_post_param("clientSubSystemCode")
    if clientSubSystemCode == nil then
      table.insert(errors, "NO-CLIENTSUBSYSTEMCODE")
    else
      ngx.req.set_header("clientSubSystemCode", clientSubSystemCode) 
    end
  end

  if clientSubSystemCode and string.match(clientSubSystemCode,"[^(%a%d%.%-)]") then
    table.insert(errors, "INVALID-CLIENTSUBSYSTEMCODE")
    criticalError = true
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
    if clientSubSystemCode then
      txt = txt .. ' clientSubSystemCode: "' .. clientSubSystemCode .. '"'
    end
    txt = txt .. ' id: "' .. id .. '"'
    ngx.log(ngx.ERR, txt)
  end

  -- if blocking, return error string in plain text or json and return error code
  if (block and blockForMinorErrors) or criticalError then
    local error = "Invalid request. More information at https://github.com/Opetushallitus/dokumentaatio/blob/master/http.md"
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
end

return ophcommon
