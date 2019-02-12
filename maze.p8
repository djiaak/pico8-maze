pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function sample(table)
	local idx = flr(rnd(count(table)))
	return table[idx+1]
end

function debug_print(tbl) 
	for i=1,count(tbl),1
	do
		print(tbl[i])
	end
end
-->8
cell = {}
cell.__index = cell
function cell:create(row, col)
	local o = {}
	setmetatable(o, cell)
	o.row = row
	o.col = col
	o.links = {}
	return o
end

function cell:link(src, bidi)
 self.links[src] = true
 if bidi then src:link(self, false) end
 return self
end

function cell:unlink(src, bidi)
	self.links[src] = nil
	if bidi then src:unlink(self, false) end
end

function cell:get_links() 
	return self.links
end

function cell:get_link_keys()
	local keys = {}
	for k,_ in pairs(self.links) do
		add(keys, k)
	end
	return keys
end

function cell:is_linked(src)
	return self.links[src] ~= nil
end

function cell:neighbors()
	local list = {}
	if self.n~=nil then add(list, self.n) end
	if self.e~=nil then add(list, self.e) end
	if self.s~=nil then add(list, self.s) end
	if self.w~=nil then add(list, self.w) end
	return list
end

function cell:set_n(c) 
	self.n = c
end

function cell:set_e(c) 
	self.e = c
end

function cell:set_s(c) 
	self.s = c
end

function cell:set_w(c) 
	self.w = c
end	

function cell:get_n()
	return self.n
end

function cell:get_e()
	return self.e
end

function cell:get_s()
	return self.s
end

function cell:get_w()
	return self.w
end

function cell:neighbor_str(dir)
	if dir == "n" then return self:get_n() end
	if dir == "e" then return self:get_e() end
	if dir == "s" then return self:get_s() end
	if dir == "w" then return self:get_w() end
end

function cell:get_row()
	return self.row
end

function cell:get_col()
	return self.col
end

function cell:links_bits()
	local bits=0
	if self.links[self.n] then bits = bits + 1 end
	if self.links[self.e] then bits = bits + 2 end
	if self.links[self.s] then bits = bits + 4 end
	if self.links[self.w] then bits = bits + 8 end
	return bits
end

function cell:calc_distances() 
	local dist = distances:create(self)
	local frontier = {}
	add(frontier, self)
	while count(frontier) > 0 do
		local new_frontier = {}
		for i=1,count(frontier),1 do
			local cell = frontier[i]
			for _, linked in pairs(cell:get_link_keys()) do
				if not dist:get(linked) then
					dist:set(linked, dist:get(cell) + 1)
					add(new_frontier, linked)
				end
			end 
		end
		frontier = new_frontier
	end
	return dist
end
-->8
grid = {}
grid.__index = grid
function grid:create(rows, cols)
	local o = {}
	setmetatable(o, grid)
	o.rows = rows
	o.cols = cols
	o.grid = o:prepare_grid()
	o:configure_cells(o.grid)
	return o
end

function grid:get_rows() 
	return self.rows
end

function grid:get_cols() 
	return self.cols
end

function grid:prepare_grid()
	local g={}
	for r = 1,self.rows,1
	do
		g[r] = {}
		for c = 1,self.cols,1
		do
			g[r][c] = cell:create(r,c)
		end
	end
	return g
end

function grid:lookup(r,c)
	if r <= 0 then return nil end
	if c <= 0 then return nil end
	if r > self.rows then return nil end
	if c > self.cols then return nil end
	return self.grid[r][c]
end

function grid:configure_cells(g)
	for r = 1,self.rows,1
	do
		for c = 1,self.cols,1
		do
			local cell=self:lookup(r,c)
			cell:set_n(self:lookup(r-1,c))
			cell:set_s(self:lookup(r+1,c))
			cell:set_w(self:lookup(r,c-1))
			cell:set_e(self:lookup(r,c+1))
		end
	end
end

function grid:random_cell()
	local row = flr(rnd(self.rows)) + 1
	local col = flr(rnd(self.cols)) + 1
	return self:lookup(row,col)
end

function grid:size()
	return self.rows * self.cols
end

function grid:each_row()
	local i=0
	local n=self.rows
	return function()
		i = i + 1
		if i <= n then return self.grid[i] end
	end
end

function grid:each_cell()
 local iter = self:each_row()
 local n = self.cols
 local el = iter()
 while true do
 	local i = 0
 	return function()
 		i = i + 1
		if i > n then
			i = 1
			el = iter()
		end
		if el == nil then return nil end
		return el[i]
 	end
 end
end

function grid:to_string()
	local lines = {}
	add(lines,"/" .. rep_str("---+",self.cols))
	local iter = self:each_row()
	while true do
		local row = iter()
		if row == nil then break end
		local top = "|"
		local bottom = "+"
		for i=1,self.cols,1
		do
			local c
			if row[i] == nil then c=cell:create(-1,-1) else c=row[i] end
			local body="   "
			local east_bound
			if c:is_linked(c:get_e()) then east_bound = " " else east_bound = "|" end
			top = top .. body .. east_bound
			local south_bound
			if c:is_linked(c:get_s()) then south_bound="   " else south_bound="---" end
			local corner = "+"
			bottom = bottom .. south_bound .. corner  
		end
		add(lines,top)
		add(lines,bottom)
	end
	return lines
end
-->8
binary_tree = {}
binary_tree.__index = binary_tree
function binary_tree:create()
	local o = {}
	setmetatable(o, binary_tree)
	return o
end

function binary_tree:on(g)
	local iter = g:each_cell()
	while true do
		local cell = iter()
		if cell == nil then break end
		local neighbors = {}
		if cell:get_n() ~= nil then add(neighbors, cell:get_n()) end
		if cell:get_e() ~= nil then add(neighbors, cell:get_e()) end
		local index = flr(rnd(count(neighbors)))+1
		local neighbor = neighbors[index]
		if neighbor ~= nil then cell:link(neighbor, true) end
	end
end

function binary_tree:adjust_goal_for_bias(start_row, start_col, goal_row, goal_col, row_count, col_count)
	--northern and eastern row always clear - if start is here
	--move goal to southwestern corner so solution isn"t trivial
	if start_row==1 or start_col==col_count then
		return {
			goal_row=row_count,
			goal_col=1	
		}
	end
	return {
		goal_row=goal_row,
		goal_col=goal_col
	}
end
-->8
sidewinder = {}
sidewinder.__index = sidewinder
function sidewinder:create()
	local o = {}
	setmetatable(o, sidewinder)
	return o
end

function sidewinder:on(grid)
	local r_iter = grid:each_row()
	while true do
		local row = r_iter()
		if row == nil then break end
		local run = {}
		for i=1,count(row),1
		do
			local cell = row[i]
			add(run, cell)
			local at_eastern_bound = cell:get_e() == nil
			local at_northern_bound = cell:get_n() == nil
			local should_close_out = at_eastern_bound or 
				(not at_northern_bound and flr(rnd(2))==0)
			if should_close_out then
				local member = sample(run)
				if member:get_n() then member:link(member:get_n(), true) end
				run = {}
			else
				cell:link(cell:get_e(), true)
			end
		end
	end
end

function sidewinder:adjust_goal_for_bias(start_row, start_col, goal_row, goal_col, row_count, col_count)
	--northern row is always clear - if start is on the 
	--northern row move goal to southern so solution isn"t 
	--trivial
	if start_row == 1 then
		return {
			goal_row=row_count,
			goal_col=goal_col,
		}
	end
	return {
		goal_row=goal_row,
		goal_col=goal_col
	}

end
-->8
aldous_broder = {}
aldous_broder.__index = aldous_broder
function aldous_broder:create()
	local o = {}
	setmetatable(o, aldous_broder)
	return o
end

function aldous_broder:on(grid)
	local cell=grid:random_cell()
	local unvisited=grid:size()-1

	while unvisited>0 do
		local neighbor=sample(cell:neighbors())
		if count(neighbor:get_link_keys())==0 then
			cell:link(neighbor, true)
			unvisited=unvisited-1
		end
		cell=neighbor
	end
end
-->8
distances = {}
distances.__index = distances
function distances:create(root)
	local o = {}
	setmetatable(o, distances)
	o.root = root
	o.cells = {}
	o.cells[root] = 0
	return o
end

function distances:get(cell)
	return self.cells[cell]
end

function distances:set(cell, distance)
	self.cells[cell] = distance
end

function distances:get_cells()
	local keys={}
	for k,_ in pairs(self.cells) do
		add(keys, k)
	end
	return keys
end
-->8
function grid_to_map(g)
	local iter = g:each_cell()
	while true do
		local cell = iter()
		if cell == nil then break end
		local links = cell:links_bits()
		mset(cell:get_col()-1, cell:get_row()-1, links)
	end
end


local game_state_menu=0
local game_state_play=1
local game_state_lose=2

local current_game_state
local max_col_count=16
local row_count=15
local col_count=max_col_count
local button_down=nil
local tile_size=8
local screen_width = tile_size*max_col_count
local maze_types = {
	{ type=binary_tree, name="binary tree", color=12 },
	{ type=sidewinder, name="sidewinder", color=8 },
	{ type=aldous_broder, name="aldous-broder", color=11 }
}

--menu stuff
local selected_maze_type_idx = 1

--play stuff
local g
local dist
local start_r
local start_c
local end_r
local end_c
local player_r
local player_c
local spr_player=16
local spr_goal=spr_player+1
local score
local score_perfect
local play_time_start
local play_time=25
local play_time_increment=5
local shake_until_time=0

function _init() 
	cartdata("djiaak_maze_1")
	transfer_to_menu()
end

function _draw()
	if current_game_state==game_state_menu then draw_menu() end
	if current_game_state==game_state_play then draw_play() end
	if current_game_state==game_state_lose then draw_lose() end
end

function _update()
	if current_game_state==game_state_menu then update_menu() end
	if current_game_state==game_state_play then update_play() end
	if current_game_state==game_state_lose then update_lose() end
end

function print_center(str, y, color, x_offset)
	local x=screen_width/2 - #str*2
	if x_offset!=nil then x=x+x_offset*2 end
	print(str, x, y, color)
	return x
end

function init_start_end_coords(s_x, s_y)
	local e_x, e_y
	repeat
		e_x = flr(rnd(2))
		e_y = flr(rnd(2))
	until not (e_x == s_x and e_y == s_y)
	start_c = s_x * (col_count-1) + 1
	start_r = s_y * (row_count-1) + 1
	end_c = e_x * (col_count-1) + 1
	end_r = e_y * (row_count-1) + 1
	player_c=start_c
	player_r=start_r
	if maze_types[selected_maze_type_idx].type.adjust_goal_for_bias~=nil then
		local adjusted_goal = maze_types[selected_maze_type_idx]
			.type:adjust_goal_for_bias(player_r, player_c, end_r, end_c, row_count, col_count)
		end_c=adjusted_goal.goal_col
		end_r=adjusted_goal.goal_row
	end
end

function init_maze()
	perfect=true
	g = grid:create(row_count,col_count)
  maze_types[selected_maze_type_idx].type:create():on(g)
	dist = g:lookup(end_r,end_c):calc_distances()
	grid_to_map(g)
end

function transfer_to_play()
	play_time_start=time()
	score=0
	score_perfect=0
	current_game_state=game_state_play
	init_start_end_coords(0,0)
	init_maze()
end

function transfer_to_menu()
	current_game_state=game_state_menu

	for i,maze_type in pairs(maze_types) do
		maze_type.high_score=dget(get_high_score_data_idx(i))
		maze_type.high_perfect=dget(get_high_perfect_data_idx(i))
	end
end

function get_high_score_data_idx(i)
	return (i-1)*2
end

function get_high_perfect_data_idx(i)
	return (i-1)*2+1
end

function transfer_to_lose()
	local high_score_idx=get_high_score_data_idx(selected_maze_type_idx)
	local high_perfect_idx=get_high_perfect_data_idx(selected_maze_type_idx)
	local high_score=dget(high_score_idx)
	local high_perfect=dget(high_perfect_idx)
	if score>high_score then dset(high_score_idx,score) end
	if score_perfect>high_perfect then dset(high_perfect_idx,score_perfect) end

	current_game_state=game_state_lose
end

function get_button_pressed()
	local button=nil
  if btn(0) then button = "w" end
  if btn(1) then button = "e" end
  if btn(2) then button = "n" end
  if btn(3) then button = "s" end
  if btn(4) then button = "o" end
  if btn(5) then button = "x" end
	if button==nil then
		button_down=nil
		return nil
	end
	if button==button_down then return nil end
	button_down=button
	return button
end

function draw_menu() 
	cls(0)
	local y = 20
	local flip = flr(time()*2) % 2 == 0
	print_center("select a maze algorithm", y, 7)
	y=y+tile_size*2
	for _,maze_type in pairs(maze_types) do
		local x=print_center(maze_type.name .. " " .. maze_type.high_perfect .. "/" .. maze_type.high_score, 
			y, maze_type.color)
		if maze_types[selected_maze_type_idx]==maze_type then spr(spr_player, x-11, y-2,1,1,flip) end
		y = y + tile_size
	end
	y=y+tile_size*2
	print_center("⬆️⬇️select ❎start", y, 7, -3)
end

function update_menu()
	local button = get_button_pressed()
	local dir=0

	if button=="x" then transfer_to_play() end
	if button=="s" then dir=1 end
	if button=="n" then dir=-1 end
	selected_maze_type_idx = selected_maze_type_idx + dir
	selected_maze_type_idx = (selected_maze_type_idx-1) % count(maze_types) + 1
end

function next_maze()
	score = score + 1
	if perfect then score_perfect = score_perfect + 1 end
	play_time_start = play_time_start + play_time_increment
	init_start_end_coords(flr(end_c/col_count),flr(end_r/row_count))
	init_maze()
end

function update_play()
	if time()-play_time_start>play_time then
		transfer_to_lose()
	end

	local button = get_button_pressed()
	local c = g:lookup(player_r, player_c)
	if c == nil then return end
	local neighbor = c:neighbor_str(button)
	if not c:is_linked(neighbor) then return end
	if perfect and dist:get(c) != dist:get(neighbor) + 1 then
		perfect=false
		shake_until_time = time() + 1
	end
	player_c = neighbor:get_col()
	player_r = neighbor:get_row()
	
	if player_c == end_c and player_r == end_r then next_maze() end
end

function draw_goal(dist)
	local current_cell = g:lookup(end_r, end_c)
	local current_dist = dist:get(current_cell)
	while current_dist>0 do
		for k,neighbor in pairs(current_cell:neighbors()) do
			if dist:get(neighbor) == current_dist - 1 and current_cell:is_linked(neighbor) then
				current_dist = current_dist - 1
				line(
					(current_cell:get_col()-1) * tile_size + tile_size/2, 
					(current_cell:get_row()-1) * tile_size + tile_size/2,
					(neighbor:get_col()-1) * tile_size + tile_size/2,
					(neighbor:get_row()-1) * tile_size + tile_size/2, 
					10)
				current_cell = neighbor
				break
			end
		end
	end
end

function print_dist(dist)
	local iter = g:each_cell()
	while true do
		local cell = iter()
		if cell == nil then break end
		local cell_distance = dist:get(cell)
		print(cell_distance, (cell:get_col()-1) * tile_size + 1, (cell:get_row()-1) * tile_size + 1, 10)
	end
end

function draw_timer()
	local width = (screen_width - 2) * (1-((time()-play_time_start) / play_time))
	if width<0 then return end

	rectfill(1, 
		row_count*tile_size + 1, 
		width,
		row_count*tile_size + tile_size - 2,
		7
	)
end

function draw_play() 
	cls(maze_types[selected_maze_type_idx].color)
	
	local map_x=0
	local wrong_way_color
	if shake_until_time > time() then
		local shake_mod=flr(time()*32) % 2
		map_x=shake_mod
		if shake_mod==0 then wrong_way_color=8 else wrong_way_color=7 end 
	end 
	map(0,0,map_x,0,col_count,row_count)
	if shake_until_time > time() then print_center("wrong way!", 52, wrong_way_color) end 
	draw_timer()
	local flip_player = flr(time()*2) % 2 == 0
	local flip_goal = flr(time()*4) % 2 == 0
	spr(spr_player, (player_c-1)*tile_size, (player_r-1)*tile_size,1,1,flip_player)
	spr(spr_goal, (end_c-1)*tile_size, (end_r-1)*tile_size,1,1,flip_goal)
end

function update_lose()
	local button=get_button_pressed()
	if button=="x" then transfer_to_menu() end
end

function draw_lose()
	local y = 40
	rectfill(21, y+1, screen_width-20+1, y + tile_size*5+1, 0)
	rectfill(20, y, screen_width-20, y + tile_size*5, 7)
	print_center("out of time!", y + tile_size, 8)
	print_center("perfect mazes: " .. score_perfect, y + tile_size*2, 8)
	print_center("total mazes: " .. score, y + tile_size*3, 8)
end




__gfx__
00000000001666600000000000166660000000000016666000000000001666600000000000166660000000000016666000000000001666600000000000166660
00000000001666600000000000166660000000000016666000000000001666600000000000166660000000000016666000000000001666600000000000166660
00111110001666600011111100166666001111100016666000111111001666661111111011166660111111111116666611111110111666601111111111166666
00166660001666600016666600166666001666600016666000166666001666666666666066666660666666666666666666666660666666606666666666666666
00166660001666600016666600166666001666600016666000166666001666666666666066666660666666666666666666666660666666606666666666666666
00166660001666600016666600166666001666600016666000166666001666666666666066666660666666666666666666666660666666606666666666666666
00166660001666600016666600166666001666600016666000166666001666666666666066666660666666666666666666666660666666606666666666666666
00000000000000000000000000000000001666600016666000166660001666600000000000000000000000000000000000666660006666600066666000666660
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aaa0000009a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a1a1a00009aaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaa0099aaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a111a000aaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33aaa333009aaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
333d333309aaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
033333009aa009aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000215005150061500716008160091500a1500b1500c1500d1500e1500f1401214012140101400e1400e1400e1400f15014150161501915019150161501f1402314027140221401b140171500c1500c150
000100001055013550145501455014550135501255012550115501155011550105501055012550145501a5501c5501e550205502355023550235501f5501b5501e55020550215502355025550265502755028550
