


-- stores functions and door_type table
mob_door_handling = {};

-- use this function instead of the local function "walkable" in burlis pathfinder algorithm
-- (the pathfinder can be found at https://github.com/MarkuBu/pathfinder)
mob_door_handling.walkable = function(node)
	if( not( node ) or not( node.name ) or not( minetest.registered_nodes[node.name])) then
		return true;
	end
	if( mob_door_handling and mob_door_handling.door_type and mob_door_handling.door_type[ node.name ]) then
		return false;
	end
	return minetest.registered_nodes[node.name].walkable
end


-- open doors and gates
-- 	pos	position that is to be checked for door-status
-- 	self	the npc (required: self.pos)
-- 	target	the position the mob wants to reach; distance to self.pos is calculated to some degree
mob_door_handling.open_door = function( pos, self, target )
	-- open the closed door in front of the npc (the door is the next target on the path)
	local node = minetest.get_node( pos );
	if( not( node ) or not( node.name )) then
		return;
	end
	local door_type = mob_door_handling.door_type[ node.name ];

	-- doors from minetest_game and from the cottages mod
	if(     door_type == "door_a_b" and self and self.pos and target) then
		-- we cannot rely on the open/closed state as stored in "state" of the door as that depends on how
		-- the door was placed; instead, check if the door is "open" in the direction in which the mob
		-- wants to move
		local move_in_z_direction = math.abs( self.pos.z - target.z ) > math.abs( self.pos.x - target.x );
		if( (    move_in_z_direction  and node.param2 % 2 == 0)
		  or(not(move_in_z_direction) and node.param2 % 2 == 1)) then
			-- open the door by emulating a right-click
			minetest.registered_nodes[node.name].on_rightclick(pos,node,nil)
			self._door_pos = pos;
		end

	-- open a closed gate; gates have a diffrent node type for open and closed
	elseif( door_type == "gate_closed" ) then
		minetest.registered_nodes[node.name].on_rightclick(pos,node,nil)
		self._gate_pos = pos;
	end
end


-- a single right-click ought to be enough (it is no problem if that opens the door again)
mob_door_handling.close_door = function( pos )
	if( not( pos )) then
		return;
	end
	local node = minetest.get_node( pos );
	if( not( node ) or not( node.name )) then
		return;
	end
	local door_type = mob_door_handling.door_type[ node.name ];

	-- toggle doors, close gates
	if( door_type == "door_a_b" or door_type == "gate_open" ) then
		minetest.registered_nodes[node.name].on_rightclick(pos,node,nil);
	end
end


-- returns for a given door node the type of door:
--   door_a_b     typical door from minetest_game; the question of weather it
--                is open or closed depends on from where to where the mob
--                wants to go
--   gate_closed  a closed gate
--   gate_open    opened gate
--   ignore       can be walked through but requires no action
--                (used for doors:hidden, the upper part of a door)
mob_door_handling.door_type = {};

for k,v in pairs( minetest.registered_nodes ) do
	if( string.sub( k, 1, 6)=="doors:" ) then
		local str = string.sub( k, -2, -1 );
		-- a door from minetest_game
		if(     string.sub( k, -2, -1) == "_a"
		     or string.sub( k, -2, -1) == "_b" ) then
			mob_door_handling.door_type[ k ] = "door_a_b";

		-- a (closed) gate from minetest_game
		elseif( string.sub( k, -7, -1) == "_closed") then
			mob_door_handling.door_type[ k ] = "gate_closed";

		-- opened gate from minetest_game
		elseif( string.sub( k, -5, -1) == "_open") then
			mob_door_handling.door_type[ k ] = "gate_open";

		-- the upper part of a door
		elseif( k == "doors:hidden" ) then
			mob_door_handling.door_type[ k ] = "ignore";
		end
	

	-- half door and half door inverted from the cottages mod
	elseif( k == "cottages:half_door" ) then
		mob_door_handling.door_type[ k ] = "door_a_b";
	elseif( k == "cottages:half_door_inverted" ) then
		mob_door_handling.door_type[ k ] = "door_a_b";

	-- gates from the gottages mod
	elseif( k == "cottages:gate_closed") then
		mob_door_handling.door_type[ k ] = "gate_closed";
	elseif( k == "cottages:gate_open") then
		mob_door_handling.door_type[ k ] = "gate_open";

	-- gates from the gates_long mod
	elseif( string.sub( k, 1, 29 ) == "gates_long:fence_gate_closed_") then
		mob_door_handling.door_type[ k ] = "gate_closed";
	elseif( string.sub( k, 1, 21 ) == "gates_long:gate_open_") then
		mob_door_handling.door_type[ k ] = "gate_open";
	end

	-- just for debugging
--	if( mob_door_handling.door_type[k] ) then print( "permits_passage: "..tostring(k)); end
end
