function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

local http_xss_verbs = Set {"POST", "PUT", "DELETE", "PATCH"}
local error = "Invalid request, please read http://oph.fi"

local block = false

if http_xss_verbs[ngx.var.request_method] and (ngx.var.cookie_csrf == nil or not (ngx.var.cookie_csrf == ngx.var.http_x_csrf)) then
	block = true
end

if block then
	if ngx.var.http_accept and string.find(ngx.var.http_accept, 'application/json') then
		ngx.header.content_type = "application/json; charset=utf-8"  
		ngx.say("{'error': '", error, "'}")
	else
		ngx.say("Error: ", error)		
	end
    ngx.exit(ngx.HTTP_FORBIDDEN)
end	