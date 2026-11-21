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
    title = nil, _xlabel = "x", _ylabel = "y", _zlabel = "z",
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

function Axes3D:view(elev, azim)
  if type(elev) ~= "number" or type(azim) ~= "number" then
    error("view expects numeric elev and azim")
  end
  self.elev, self.azim = elev, azim
  return self
end

function Axes3D:xlim(lo, hi) self._xlim = { lo, hi }; return self end
function Axes3D:ylim(lo, hi) self._ylim = { lo, hi }; return self end
function Axes3D:zlim(lo, hi) self._zlim = { lo, hi }; return self end

function Axes3D:surface(x, y, z, opts)
  local data = require("luaplotlib.data")
  local rows, cols, zz = data.matrix(z, "surface z")
  local xx = x
  local yy = y
  if type(x) ~= "table" or type(x[1]) ~= "table" then
    if #x < cols then
      error("surface x must have at least " .. cols .. " entries")
    end
    xx = {}
    for r = 1, rows do
      xx[r] = {}
      for c = 1, cols do xx[r][c] = x[c] end
    end
  end
  if type(y) ~= "table" or type(y[1]) ~= "table" then
    if #y < rows then
      error("surface y must have at least " .. rows .. " entries")
    end
    yy = {}
    for r = 1, rows do
      yy[r] = {}
      for c = 1, cols do yy[r][c] = y[r] end
    end
  end
  opts = opts or {}
  self._series[#self._series + 1] = {
    kind = "surface", x = xx, y = yy, z = zz, rows = rows, cols = cols,
    color = opts.color or "#1f77b4", label = opts.label,
  }
  return self
end

function Axes3D:mesh(x, y, z, opts)
  return self:surface(x, y, z, opts)
end

function Axes3D:title(text) self._title = text; return self end
function Axes3D:xlabel(text) self._xlabel = text; return self end
function Axes3D:ylabel(text) self._ylabel = text; return self end
function Axes3D:zlabel(text) self._zlabel = text; return self end

local function bounds(axes)
  local b = { minx = math.huge, maxx = -math.huge, miny = math.huge,
    maxy = -math.huge, minz = math.huge, maxz = -math.huge }
  for _, s in ipairs(axes._series) do
    if s.kind == "surface" then
      for r = 1, s.rows do for c = 1, s.cols do
        b.minx = math.min(b.minx, s.x[r][c]); b.maxx = math.max(b.maxx, s.x[r][c])
        b.miny = math.min(b.miny, s.y[r][c]); b.maxy = math.max(b.maxy, s.y[r][c])
        b.minz = math.min(b.minz, s.z[r][c]); b.maxz = math.max(b.maxz, s.z[r][c])
      end end
    else
    for i = 1, #s.x do
      b.minx = math.min(b.minx, s.x[i]); b.maxx = math.max(b.maxx, s.x[i])
      b.miny = math.min(b.miny, s.y[i]); b.maxy = math.max(b.maxy, s.y[i])
      b.minz = math.min(b.minz, s.z[i]); b.maxz = math.max(b.maxz, s.z[i])
    end
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
  local x0, x1 = pad(b.minx, b.maxx)
  local y0, y1 = pad(b.miny, b.maxy)
  local z0, z1 = pad(b.minz, b.maxz)
  b.minx = axes._xlim and axes._xlim[1] or x0
  b.maxx = axes._xlim and axes._xlim[2] or x1
  b.miny = axes._ylim and axes._ylim[1] or y0
  b.maxy = axes._ylim and axes._ylim[2] or y1
  b.minz = axes._zlim and axes._zlim[1] or z0
  b.maxz = axes._zlim and axes._zlim[2] or z1
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
  local ordered = {}
  for _, s in ipairs(self._series) do ordered[#ordered+1] = s end
  table.sort(ordered, function(a, b)
    local function depth(s)
      local total = 0
      for i=1,#s.z do total = total + s.z[i] end
      return total / #s.z
    end
    return depth(a) < depth(b)
  end)
  for _, s in ipairs(ordered) do
    add('<g class="series series-'..s.kind..'">')
    if s.kind == "surface" then
      for r = 1, s.rows do
        for c = 1, s.cols - 1 do
          local x1,y1 = project(s.x[r][c], s.y[r][c], s.z[r][c])
          local x2,y2 = project(s.x[r][c+1], s.y[r][c+1], s.z[r][c+1])
          add(string.format('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1"/>',x1,y1,x2,y2,s.color))
        end
      end
      for c = 1, s.cols do
        for r = 1, s.rows - 1 do
          local x1,y1 = project(s.x[r][c], s.y[r][c], s.z[r][c])
          local x2,y2 = project(s.x[r+1][c], s.y[r+1][c], s.z[r+1][c])
          add(string.format('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1"/>',x1,y1,x2,y2,s.color))
        end
      end
      add('</g>')
    else
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
  end
  local function tick(value, lo, hi)
    local p = (value - lo) / (hi - lo)
    if p < 0 then p = 0 elseif p > 1 then p = 1 end
    return p
  end
  local function ticks_for(lo, hi)
    local result = {}
    for i = 0, 4 do result[#result+1] = lo + (hi - lo) * i / 4 end
    return result
  end
  add('<g class="axes3d-ticks" font-size="10" fill="#333333" stroke="#333333">')
  for _, value in ipairs(ticks_for(b.minx, b.maxx)) do
    local p = tick(value, b.minx, b.maxx)
    local x1, y1 = project(value, b.miny, b.minz)
    local x2, y2 = project(value, b.miny - (b.maxy-b.miny)*0.04, b.minz)
    add(string.format('<line x1="%s" y1="%s" x2="%s" y2="%s"/>',x1,y1,x2,y2))
    add(string.format('<text x="%s" y="%s" text-anchor="middle" stroke="none">%s</text>',x2,y2+12,util.fmt_tick(value)))
  end
  for _, value in ipairs(ticks_for(b.miny, b.maxy)) do
    local x1, y1 = project(b.minx, value, b.minz)
    local x2, y2 = project(b.minx - (b.maxx-b.minx)*0.04, value, b.minz)
    add(string.format('<line x1="%s" y1="%s" x2="%s" y2="%s"/>',x1,y1,x2,y2))
    add(string.format('<text x="%s" y="%s" text-anchor="end" stroke="none">%s</text>',x2-4,y2+4,util.fmt_tick(value)))
  end
  for _, value in ipairs(ticks_for(b.minz, b.maxz)) do
    local x1, y1 = project(b.minx, b.miny, value)
    local x2, y2 = project(b.minx, b.miny - (b.maxy-b.miny)*0.04, value)
    add(string.format('<line x1="%s" y1="%s" x2="%s" y2="%s"/>',x1,y1,x2,y2))
    add(string.format('<text x="%s" y="%s" text-anchor="middle" stroke="none">%s</text>',x2,y2+12,util.fmt_tick(value)))
  end
  add('</g>')
  add(string.format('<text class="xlabel" x="%s" y="%s" font-size="12" text-anchor="middle">%s</text>',cx,self.height-46,util.escape_xml(self._xlabel or "x")))
  add(string.format('<text class="ylabel" x="%s" y="%s" font-size="12" text-anchor="middle">%s</text>',cx-180,self.height-70,util.escape_xml(self._ylabel or "y")))
  add(string.format('<text class="zlabel" x="%s" y="%s" font-size="12" text-anchor="middle">%s</text>',cx+180,self.height-70,util.escape_xml(self._zlabel or "z")))
  add('</svg>')
  return table.concat(out,"\n").."\n"
end

function Axes3D:savefig(path)
  if type(path) ~= "string" or path == "" then
    error("fig3d:savefig path must be a non-empty string", 2)
  end
  local lower = path:lower()
  if lower:sub(-4) == ".png" then
    return require("luaplotlib.export").png(self:to_svg(), path)
  elseif lower:sub(-4) == ".pdf" then
    return require("luaplotlib.export").pdf(self:to_svg(), path)
  elseif lower:sub(-4) ~= ".svg" then
    error("fig3d:savefig supports .svg, .png, and .pdf paths", 2)
  end
  local f=assert(io.open(path,"wb")); f:write(self:to_svg()); f:close(); return path
end

return Axes3D
