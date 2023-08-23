local SpawnTable = {}
surface.CreateFont(
    "Waypoint_big",
    {
        font = "DermaLarge",
        size = 600,
        weight = 5000,
        antialias = true,
    }
)

local color1 = Color(255, 255, 255)
local color2 = Color(0, 0, 0, 150)
local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local xy = 110
local xy2 = -(xy / 2)
local xy4 = -(xy * 4)
local cam_Start3D2D = cam.Start3D2D
local cam_IgnoreZ = cam.IgnoreZ
local draw_RoundedBox = draw.RoundedBox
local draw_WordBox = draw.WordBox
local cam_End3D2D = cam.End3D2D
local pairs=pairs
local function waypoint_draw()
    local angles = LocalPlayer():EyeAngles()
    if not SpawnTable then
        hook.Remove('PostDrawOpaqueRenderables', 'spawn_fox_hide')
        return
    end

    for k, v in pairs(SpawnTable) do
        if not k then continue end
        local text = "[" .. k .. "]"
        surface_SetFont("Waypoint_big")
        local TextWidth_wp = surface_GetTextSize(text)
        angles:RotateAroundAxis(angles:Forward(), 90)
        angles:RotateAroundAxis(angles:Right(), 90)
        cam_Start3D2D(Vector(v), angles, 0.1)
        cam_IgnoreZ(true)
        draw_RoundedBox(80, xy2, -xy, xy, xy, color1)
        draw_WordBox(2, -TextWidth_wp * 0.5, xy4, text, "Waypoint_big", color2, color1)
        cam_IgnoreZ(false)
        cam_End3D2D()
    end
end

net.Receive(
    "spawn_show_reload_fox",
    function()
        --if LocalPlayer().Bool then
        SpawnTable = net.ReadTable()
        hook.Remove('PostDrawOpaqueRenderables', 'spawn_fox_hide')
        hook.Add('PostDrawOpaqueRenderables', 'spawn_fox_hide', waypoint_draw)
        LocalPlayer().Bool = true
    end
)

--end
net.Receive(
    "spawn_show_fox",
    function()
        LocalPlayer().Bool = net.ReadBool()
        SpawnTable = net.ReadTable()
        if LocalPlayer().Bool then
            hook.Add('PostDrawOpaqueRenderables', 'spawn_fox_hide', waypoint_draw)
        else
            hook.Remove('PostDrawOpaqueRenderables', 'spawn_fox_hide')
        end
    end
)