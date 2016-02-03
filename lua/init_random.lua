function init()
  local urand = assert (io.open ('/dev/urandom', 'rb'))
  local rand  = urand or assert (io.open ('/dev/random', 'rb'))
  local a,b,c,d = rand:read(4):byte(1,4);
  local seed = a*0x1000000 + b*0x10000 + c *0x100 + d;
  math.randomseed(seed);
end

init()