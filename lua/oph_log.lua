-- lua does not include set, create a dictionary
function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

local block = false
local errors = {}

-- Double submit protection for CSRF:
-- CSRF cookie and X-CSRF must exist andhave same content for "POST", "PUT", "DELETE", "PATCH"
local http_xss_verbs = Set {"POST", "PUT", "DELETE", "PATCH"}
if http_xss_verbs[ngx.var.request_method] then
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
end

---[[
-- Caller-id and Transaction-ID header checks
if ngx.var.http_caller_id == nil then
  block = true
  table.insert(errors, "NO-CALLER-ID")
end

if ngx.var.http_transaction_id == nil then
  block = true
  table.insert(errors, "NO-TRANSACTION-ID")
end
--]]

if next(errors) then
  ngx.log(ngx.ERR, "ERROR:", table.concat(errors, "|"))
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
