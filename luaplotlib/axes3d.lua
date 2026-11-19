-- Minimal true 3-D axes: orthographic projection, box, ticks, line/scatter.
local util = require("luaplotlib.util")

local Axes3D = {}
Axes3D.__index = Axes3D

local function sequence(value, name)
  local data = require("luaplotlib.data")
  return data.sequence(value, name)
end

function Axes3D.new(opts)
  opts = opts or {}
  return setmetatable({
    width = opts.width or 720, height = opts.height or 520, dpi = opts.dpi or 100,
    elev = opts.elev or 30, azim = opts.azim or -60,
    title = nil, xlabel = "x", ylabel = "y", zlabel = "z",
    _series = {}, _xlim = nil, _ylim = nil, _zlim = nil,
  }, Axes3D)
end

function Axes3D:plot(x, y, z, opts)
  local xv, yv, zv = sequence(x, "plot3 x"), sequence(y, "plot3 y"),
    sequence(z, "plot3 z")
  if #xv ~= #yv or #xv ~= #zv then error("plot3 vectors must match") end
  opts = opts or {}
  self._series[#self._series + 1] = { kind = "line", x = xv, y = yv, z = zv,
    color = opts.color or "#1f77b4", label = opts.label }
  return self
end

function Axes3D:scatter(x, y, z, opts)
  local xv, yv, zv = sequence(x, "scatter3 x"), sequence(y, "scatter3 y"),
    sequence(z, "scatter3 z")
  if #xv ~= #yv or #xv ~= #zv then error("scatter3 vectors must match") end
  opts = opts or {}
  self._series[#self._series + 1] = { kind = "scatter", x = xv, y = yv,
    z = zv, color = opts.color or "#ff7f0e", label = opts.label }
  return self
end

function Axes3D:title(text) self._title = text; return self end
function Axes3D:xlabel(text) self._xlabel = text; return self end
function Axes3D:ylabel(text) self._ylabel = text; return self end
function Axes3D:zlabel(text) self._zlabel = text; return self end

local function bounds(axes)
  local b = { minx = math.huge, maxx = -math.huge, miny = math.huge,
    maxy = -math.huge, minz = math.huge, maxz = -math.huge }
  for _, s in ipairs(axes._series) do
    for i = 1, #s.x do
      b.minx = math.min(b.minx, s.x[i]); b.maxx = math.max(b.maxx, s.x[i])
      b.miny = math.min(b.miny, s.y[i]); b.maxy = math.max(b.maxy, s.y[i])
      b.minz = math.min(b.minz, s.z[i]); b.maxz = math.max(b.maxz, s.z[i])
    end
  end
  if b.minx == math.huge then
    b = { minx=0,maxx=1,miny=0,maxy=1,minz=0,maxz=1 }
  end
  local function pad(lo, hi)
    if lo == hi then return lo - 0.5, hi + 0.5 end
    local p = (hi - lo) * 0.1
    return lo - p, hi + p
  end
  b.minx, b.maxx = axes._xlim and axes._xlim[1] or pad(b.minx, b.maxx),
    axes._xlim and axes._xlim[2] or pad(b.maxx, b.maxx)
  b.miny, b.maxy = pad(b.miny, b.maxy)
  b.minz, b.maxz = pad(b.minz, b.maxz)
  return b
end

function Axes3D:to_svg()
  local b = bounds(self)
  local cx, cy = self.width / 2, self.height / 2 + 20
  local scale = math.min(self.width, self.height) * 0.28
  local yaw, pitch = math.rad(self.azim), math.rad(self.elev)
  local function project(x, y, z)
    local nx = (x - b.minx) / (b.maxx - b.minx) * 2 - 1
    local ny = (y - b.miny) / (b.maxy - b.miny) * 2 - 1
    local nz = (z - b.minz) / (b.maxz - b.minz) * 2 - 1
    local rx = nx * math.cos(yaw) - ny * math.sin(yaw)
    local ry = nx * math.sin(yaw) + ny * math.cos(yaw)
    local sx = rx
    local sy = ry * math.cos(pitch) - nz * math.sin(pitch)
    return cx + sx * scale, cy - sy * scale
  end
  local out = {}
  local function add(v) out[#out + 1] = v end
  add('<?xml version="1.0" encoding="UTF-8"?>')
  add(string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s" role="img" aria-label="%s">',
    self.width, self.height, self.width, self.height,
    util.escape_xml(self._title or "3-D plot")))
  add('<rect width="'..self.width..'" height="'..self.height..'" fill="#ffffff"/>')
  if self._title then add(string.format('<text x="%s" y="28" font-size="18" text-anchor="middle">%s</text>', cx, util.escape_xml(self._title))) end
  add('<g class="axes3d" stroke="#333333" fill="none">')
  local corners = {}
  for _, x in ipairs({b.minx,b.maxx}) do for _, y in ipairs({b.miny,b.maxy}) do for _, z in ipairs({b.minz,b.maxz}) do
    corners[#corners+1] = {x,y,z}
  end end end
  local pairs = {
    {1,2},{3,4},{5,6},{7,8},{1,3},{2,4},{5,7},{6,8},{1,5},{2,6},{3,7},{4,8}
  }
  for _, p in ipairs(pairs) do
    local a, c = corners[p[1]], corners[p[2]]
    local x1,y1 = project(a[1],a[2],a[3]); local x2,y2=project(c[1],c[2],c[3])
    add(string.format('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke-width="1"/>',x1,y1,x2,y2))
  end
  add('</g>')
  for _, s in ipairs(self._series) do
    add('<g class="series series-'..s.kind..'">')
    for i=1,#s.x do
      local px,py=project(s.x[i],s.y[i],s.z[i])
      if s.kind=="scatter" then
        add(string.format('<circle cx="%s" cy="%s" r="3" fill="%s"/>',px,py,s.color))
      elseif i>1 then
        local qx,qy=project(s.x[i-1],s.y[i-1],s.z[i-1])
        add(string.format('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2"/>',qx,qy,px,py,s.color))
      end
    end
    add('</g>')
  end
  add(string.format('<text x="%s" y="%s" font-size="12" text-anchor="middle">%s</text>',cx,self.height-24,util.escape_xml(self._xlabel or "x")))
  add('</svg>')
  return table.concat(out,"\n").."\n"
end

function Axes3D:savefig(path)
  local f=assert(io.open(path,"wb")); f:write(self:to_svg()); f:close(); return path
end

return Axes3D
