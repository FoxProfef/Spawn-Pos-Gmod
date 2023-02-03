local function r(n)
    return math.Round(n, 0)
end

TableVec = {}
TableAng = {}

function SQLQuery(queryStr, func, singleRow)
    local query

    if (not singleRow) then
        query = sql.Query(queryStr)
    else
        query = sql.QueryRow(queryStr, 1)
    end

    if (query == false) then
        print("[SQLLite] ERROR", sql.LastError())
    elseif (func) then
        func(query)
    end
end

if (not sql.TableExists("players_spawn_pos")) then
    SQLQuery([[ CREATE TABLE players_spawn_pos ( 
	map text,
	mapid int,
		x int,
		y int,
		z int,
		ax int,
		ay int,
		az int
	); ]])
end

local function Mapid()
    local mapidtabl = 0
    mapid = tonumber(sql.QueryValue("SELECT count(*) from players_spawn_pos WHERE map ='" .. game.GetMap() .. "'"))
    local val = sql.Query("SELECT mapid FROM players_spawn_pos WHERE map ='" .. game.GetMap() .. "'  LIMIT " .. mapid .. ";")

    if val then
        for k, v in pairs(val) do
            if tonumber(v.mapid) > 0 and tonumber(v.mapid) > tonumber(mapidtabl) then
                mapidtabl = v.mapid
                mapid = v.mapid
            end
        end
    end

    mapid = mapid + 1

    for i = 1, mapid do
        if sql.QueryValue("SELECT count(*) from players_spawn_pos WHERE map ='" .. game.GetMap() .. "' and mapid=" .. i .. ";") ~= '0' then
            i2 = tonumber(sql.QueryRow("SELECT * from players_spawn_pos WHERE map ='" .. game.GetMap() .. "' and mapid = " .. i .. "").mapid)
        else
            i2 = 1
        end

        if i ~= i2 then
            mapid = i
            break
        end
    end

    return mapid
end

Mapid()

local function Mapid_add()
    if sql.QueryValue("SELECT count(*) from players_spawn_pos WHERE map ='" .. game.GetMap() .. "' and mapid=" .. 1 .. ";") == '0' then
        return 1
    else
        return Mapid()
    end
end

local function LoadSpawnPos()
    local mapidtabl = 0
    TableVec = {}
    TableAng = {}
    mapid2 = tonumber(sql.QueryValue("SELECT count(*) from players_spawn_pos WHERE map ='" .. game.GetMap() .. "'"))
    local val = sql.Query("SELECT mapid FROM players_spawn_pos WHERE map ='" .. game.GetMap() .. "'  LIMIT " .. mapid2 .. ";")

    if val then
        for k, v in pairs(val) do
            if tonumber(v.mapid) > 0 and tonumber(v.mapid) > tonumber(mapidtabl) then
                mapidtabl = v.mapid
                mapid2 = v.mapid
            end
        end
    end

    for i = 1, mapid2 do
        SQLQuery("SELECT * FROM players_spawn_pos WHERE mapid = " .. i .. " and map ='" .. game.GetMap() .. "';", function(d)
            if d then
                if d.map == game.GetMap() then
                    TableVec[i] = Vector(d.x, d.y, d.z)
                    TableAng[i] = Angle(d.ax, d.ay, d.az)
                end
            end
        end, true)
    end
    --
end

LoadSpawnPos()
util.AddNetworkString("spawn_show_reload_fox")

function ReloadSpawnHud(pl)
    net.Start("spawn_show_reload_fox")
    net.WriteTable(TableVec)
    net.Broadcast()
end

concommand.Add('spawn_add', function(pl)
    if not pl:IsSuperAdmin() then
        pl:PrintMessage(HUD_PRINTTALK, "Ты не Админ!")

        return
    end

    pl:PrintMessage(HUD_PRINTTALK, "Точка Спавна Добавленна!")
    local pos = pl:GetPos()
    local ang = pl:GetAngles()
    local v = (Vector(r(pos.x), r(pos.y), r(pos.z)))
    local a = (Angle(r(ang.x), r(ang.y), r(ang.z)))
    TableVec[#TableVec + 1] = v
    TableAng[#TableAng + 1] = a
    SQLQuery("INSERT INTO players_spawn_pos(map,mapid,x,y,z,ax,ay,az) VALUES('" .. game.GetMap() .. "'," .. Mapid_add() .. ',' .. r(pos.x) .. ',' .. r(pos.y) .. ',' .. r(pos.z) .. ',' .. r(ang.x) .. ',' .. r(ang.y) .. ',' .. r(ang.z) .. ");")
    --LoadSpawnPos()
    ReloadSpawnHud()
end)

concommand.Add('spawn_reset', function(pl)
    if not pl:IsSuperAdmin() then
        pl:PrintMessage(HUD_PRINTTALK, "Ты не Админ!")

        return
    end
    pl:PrintMessage(HUD_PRINTTALK, "Все точки спавна удалены!")
    SQLQuery("DELETE FROM players_spawn_pos WHERE map = '" .. game.GetMap() .. "';")
    TableVec = {}
    TableAng = {}
    ReloadSpawnHud()
end)

concommand.Add('spawn_remove', function(pl, cmd, args)
    if not pl:IsSuperAdmin() then
        pl:PrintMessage(HUD_PRINTTALK, "Ты не Админ!")

        return
    end

    if not args[1] then return end
    local num = tonumber(args[1])

    if sql.QueryValue("SELECT count(*) from players_spawn_pos WHERE map ='" .. game.GetMap() .. "' and mapid=" .. num .. ";") == '0' then
        pl:PrintMessage(HUD_PRINTTALK, "Такой точки спавна нет!")

        return
    end

    TableVec[num] = nil
    TableAng[num] = nil
    pl:PrintMessage(HUD_PRINTTALK, "Точка " .. args[1] .. " была удалена!")
    SQLQuery("DELETE FROM players_spawn_pos WHERE map = '" .. game.GetMap() .. "' and mapid=" .. args[1] .. ";")
    --LoadSpawnPos()
    ReloadSpawnHud()
end)

util.AddNetworkString("spawn_show_fox")

concommand.Add('spawn_show', function(pl, cmd, args)
    if not pl.show then
        pl:PrintMessage(HUD_PRINTTALK, "Теперь вы видите точки спавна")
        pl.show = true
        net.Start("spawn_show_fox")
        net.WriteBool(true)
        net.WriteTable(TableVec)
        net.Send(pl)
    else
        pl:PrintMessage(HUD_PRINTTALK, "Вы больше не видите точки спавна!")
        pl.show = false
        net.Start("spawn_show_fox")
        net.WriteBool(false)
        net.Send(pl)
    end
end)
hook.Add('PlayerSpawn', 'Spawn_Pos', function(ply)
    for i = 1, #TableVec do
        p = math.random(1, #TableVec)
        if not TableVec[p] then continue end

        if p ~= ply.LastSpawnFox then
            ply.LastSpawnFox = p
            break
        end
    end

    if p then
        selectv = TableVec[p]
        selecta = TableAng[p]
        ply:SetPos(selectv)
        ply:SetEyeAngles(selecta)
        p = nil
    end
	
end)
