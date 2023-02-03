SpawnTable={}
surface.CreateFont( "Waypoint_big", {
    font = "DermaLarge",
    size = 600,
    weight = 5000,
    antialias = true,
} )
local function waypoint_draw()
    for k, v in pairs(SpawnTable) do
        if not k then continue end
        local angles = LocalPlayer():EyeAngles()
        local text = "[" .. k .. "]"
        surface.SetFont("Waypoint_big")
        local TextWidth_wp = surface.GetTextSize(text)
        local xy = 10 + 100
        angles:RotateAroundAxis(angles:Forward(), 90)
        angles:RotateAroundAxis(angles:Right(), 90)
        cam.Start3D2D(Vector(v), angles, 0.1)
        cam.IgnoreZ(true)
        draw.RoundedBox(80, -xy / 2, (-xy / 2) * 2, xy, xy, Color(255, 255, 255))
        draw.WordBox(2, -TextWidth_wp * 0.5, -xy * 4, text, "Waypoint_big", Color(0, 0, 0, 150), Color(255, 255, 255))
        cam.IgnoreZ(false)
        cam.End3D2D()
    end
end
net.Receive("spawn_show_reload_fox", function()
    if LocalPlayer().Bool then
        SpawnTable = net.ReadTable()
        hook.Remove('PostDrawOpaqueRenderables', 'spawn_fox_hide')
        hook.Add('PostDrawOpaqueRenderables', 'spawn_fox_hide', waypoint_draw)
    end
end)

net.Receive("spawn_show_fox", function()
    LocalPlayer().Bool = net.ReadBool()
    SpawnTable = net.ReadTable()

    if LocalPlayer().Bool then
        hook.Add('PostDrawOpaqueRenderables', 'spawn_fox_hide', waypoint_draw)
    else
        hook.Remove('PostDrawOpaqueRenderables', 'spawn_fox_hide')
    end
end)