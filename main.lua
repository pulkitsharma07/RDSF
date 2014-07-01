--[[
The MIT License (MIT)

Copyright (c) 2014-2015 Pulkit Sharma

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

--we require some external libraries
require("AnAL")  -- naughty name, but highly usefull for playing animations
require("TEsound") -- plays the sound in a line -_-


local Quad = love.graphics.newQuad    -- this acts as a macro
local speed = 180 -- player's moving speed
local min_player_x = 0 --variables for bounding area for the player
local min_player_y = 0
local max_player_x = 0
local max_player_y = 0
local lock_input = false -- input will need to be locked when performing a special move
local timer = 0          -- timers for animation purposes
local timer2 = 0       
local move_type          --type of the move performed, in actuality it's the index of the move declared in the moves_list table
local elap = 0           -- used to store the time elapsed
local spawn_interval = 1      -- spawn interval between consecutive enemy spawns
local player_attack_range = 13   -- attack range for the player (total range  = player width + attack range)
local max_health = 1000
local player_health = max_health
local enemy_damage = 100         -- damage done by the enemy to the player
local score = 0 
local interval_updated = false;  -- used for controlling the spawn_interval
local random_inter = love.math.random(5,50)/100; -- will later add random variance to the spawn_interval
local scale_anim = 20;          -- this is used to scale the intro logo
local game_state = "started"    -- this variable stores the game states , started, running , paused,gameover




-- the load function , loading most of the resources here for later use
function love.load()

   -- Load the animation source.
   local stand_img  = love.graphics.newImage("stand.png")
   local walk_img  = love.graphics.newImage("walk.png")
   local fire_img = love.graphics.newImage("fire.png")
         enemy_img = love.graphics.newImage("enemy.png")
         kick_img = love.graphics.newImage("kick.png")
         bg= love.graphics.newImage("back04.jpg")

         menu_logo = love.graphics.newImage("logo.png")



 -- too bad , I forgot their original names xD
  font_menu = love.graphics.newFont("font.ttf",25)
  font_game = love.graphics.newFont("font2.ttf",25)



  --since game is loading , setting the current font to the menu font
  love.graphics.setFont(font_menu);

   -- Loading animations

   stand_anim = newAnimation(stand_img, 70, 105, 0.1, 0)
   walk_anim = newAnimation(walk_img, 70, 105, 0.15, 0)
   fire_anim = newAnimation(fire_img,95,126,0.1,0)
   enemy_anim = newAnimation(enemy_img,70,85,0.1,0)


   --This table will store the enemies currently on the screen

   enemies = {}



   --This table stores the moves , which the player can perform
   -- currently it has only 1 move(KICk)
   moves_list = {

                --each move is defined as a table
                {                                                             -- kick sequence 
                    iterator = 1,   -- the current frame in the animation , 1 for the first fram
                    sound = "kick.wav", -- the sound to be played during this move
                    delay = 0.1, --delay between each frame

                    --each move animation consists of several frames

                    --each frame is defined as a Quad(love.graphics.newQuad)
                      --starting position of frame (x and y ),dimensions of the fram(width and hieght), size of the full sprite sheet(width and hieght)
                    Quad(2,15,75,120,405,120); 
                    Quad(75,15,75,120,405,120);
                    Quad(150,15,105,120,405,120);
                    Quad(255,15,330-255,120,405,120);
                    Quad(330,15,405-120,120,405,120);

                }

                }                


    State = 0  --0 for idle , 1 for walking , 2 for special move


    stand_anim:setMode("bounce") --bounce back in frames
    enemy_anim:setMode("bounce")

   min_player_x=30  -- the player's bounding area
   min_player_y=170
   max_player_x=30+600
   max_player_y=480-105

              --player's spawn point
    pos_x = 100   
    pos_y = 100

              --Since , this function occurs once , when the game loads, so we start the menu music 

                  --path to file, tag, volume %
TEsound.play("menu.mp3","menu",0.20);       
end



-- this function is invoked when any key is released on the keyboard
function love.keyreleased(k)

  --if the player is not moving , then set the state to idle
  if State ~= 2 then   --     ~= is the not equal comparison operator
  State = 0
end
end
  
-- this function adds a new enemy on the screen
function spawn_enemy()
  spawn_x = max_player_x+55                 --spawn point of enemey
  spawn_y = love.math.random(min_player_y,max_player_y)  -- y coordinate is anywhere between the playable bounds

  TEsound.play("spawn.wav",{},0.10)   -- play the spawn sound for the enemy spawn

  --enemies table declared in the load function is empty right now , so we add a new element(which is a table)  in the enemy table  which represents a single DEMON

              --attributes are  the position(x and y) , state of the enemy(alive)[NOT USED RIGHT NOW], and the animation for the enemy
              -- this is the beauty of Lua written in a single line for me !!
              -- here elements on the LHS of = represent the table attributes and on the RHS the value stored in them
              -- since, we are inserted mulitple values at the same time , there for everything has to be enclosed in a table, so this is infact a table for each enemy, which is stored in the enemies table
  table.insert(enemies,{x=spawn_x, y=spawn_y, alive = 1 , animation = newAnimation(enemy_img,70,85,0.1,0)})
  --print(tostring(#enemies).." enemies , new enemy inserted at y = "..tostring(enemies[#enemies].y))
end



--update the enemies on the screen , takes an argument 'dt' , which represents the time passed

function update_enemies(dt)

  -- i,v in ipairs() , here i is the numerical component  and v is the actual object. This concept will be cleared in the following lines
  for i,v in ipairs(enemies) do  -- for all elements in the enemies table 
    v.animation:update(dt)   -- here v is equivalent to enemies[i]
    v.x = v.x - (speed-10) * dt  -- move the enemy further to the left
    if v.x < min_player_x then   -- if reached the left bound , then the enemy will no longer be visible, so  instead of eating up memory and time
     table.remove(enemies,i)     -- we can just remove that enemy !!
     TEsound.play("reached.wav",{},0.10)  -- play a little bit sound :-p 
   end
  end
end


--draws each enemy

function draw_enemies()
  for i,v in ipairs(enemies) do  -- for all enemies
    v.animation:draw(v.x,v.y)  -- just draw them !! courtesy : ANal 
  end
end


--check if the player is hit by any enemy, returns true if hit , else false

function checkhit()
hit = false
  for i,v in ipairs(enemies) do --for all enemies

          if v.y + 85 > pos_y and v.y + 85 < pos_y + 120 then -- check y collision
          if v.x <=  pos_x + 30 and v.x > pos_x then          -- check x collision
            print("HIT by"..tostring(i).." !");            
            hit  = true ;
            player_health = player_health - enemy_damage;     --update player health
         end
        end
      end

      if hit then
        print (tostring(TEsound.play("damage.wav",{},0.25)))        -- ouchh !! 
        return true      
      end

      return false

end


--this function is called automatically once a key is pressed , here argument 'k' is the keypressed

function love.keypressed(k)

  if game_state == "started" then -- if the gamestate is started that means, the user is currently seeing the menu, now since this is insice keypressed, so we can be sure the user pressed a key
    game_state = "running"    -- take the game to the next state , that is the running state
    TEsound.stop("menu");    -- stop the menu music
    love.graphics.setFont(font_game);  --change the drawing font  
    start_time = love.timer.getTime()  --initiliase timer
    TEsound.volume("back",0.25)       
    TEsound.playLooping("background.mp3","back") --start the background music
  end
end


-- this function is the core function of the Love2d framework , this function is called after 'dt' amount of time
-- as the name suggests , all the updation should be done when this function is called.

function love.update(dt)


  if game_state == "running" then --if user is playing the game

    elap_time = love.timer.getTime() - start_time
    if elap_time > (spawn_interval + random_inter ) then     -- spawn an enemy after every spawn_interval time
      
      start_time = love.timer.getTime() 
      random_inter= love.math.random(5,50)/100;
      elap_time = 0
      spawn_enemy()                           --invoking the actual function
    end

   
--GET INPUT
   if not lock_input then
   if love.keyboard.isDown('d') then
    pos_x = pos_x + speed*dt
    State = 1;
   end

   if love.keyboard.isDown('a') then
    pos_x = pos_x - speed*dt
    State = 1;
   end
  if love.keyboard.isDown('w') then
    pos_y = pos_y - (speed-20)*dt
    State = 1;
   end

   if love.keyboard.isDown('s') then
    pos_y = pos_y + (speed-20)*dt
    State = 1;
   end

   if love.keyboard.isDown('j') then                    -- kick
        State = 2
        move_type= 1
        TEsound.play(moves_list[move_type].sound,{},.20)   --play the move sound

        lock_input = true      -- we have to lock the input , because now we've to play the actual animation !!! yes this is true , this is f*cked up, poor demon died before his leg even moved XD
   end
 end


   --SPECIAL MOVE SEQUENCE , herer we are performing the animation 
   if State == 2 then
      print("number of frames is "..tostring(#moves_list[move_type]));
       timer= timer + dt  -- timer acts as summation of the time passed , it adds up dt until is becomes larger the delay defined in the moves list
       if timer > moves_list[move_type].delay then
        timer = 0  --prepare timer for the next frame 
        moves_list[move_type].iterator = moves_list[move_type].iterator + 1 --increment the iterator
        --check if any enemy is hit , if v.y + enemyht > pos_y and v.y + enemyht < pos_y+playerheight and v.x > pos_x+playerwidth and v.x < pos_x+playerwidth+playerrange
        --love.graphics.rectangle("line",pos_x,pos_y,)
        
        if moves_list[move_type].iterator > #moves_list[move_type] then  -- if iterator exceedes the sequence , that means the animation is completed
          moves_list[move_type].iterator=1   --we restore everything to their previous states
          State = 0
          lock_input = false --free the input 
        end
      end
   end


   stand_anim:update(dt)  --update all(most of) the animations on the screen
   walk_anim:update(dt)   
   fire_anim:update(dt)  
   update_enemies(dt)
   
   timer2 = timer2 + dt  -- ah, this is a hard one to explain , the thing is when checking whether the player is hit by any enemy or not
                         -- this function was reporting the same hit about 4-5 times , because of the insanely fast times it was being invoked
   if timer2 > 0.07 then
     if checkhit() then  -- therefore if function return true(we've got a hit), then the next time we check for a hit is after a little bit of time, so we can be sure that hits reported are from different enemies
      timer2 = -0.7
    else
    timer2 =0 
   end
   end



  if player_health < 0 then  -- hmm hmm
    game_state = "gameover";  -- game is over indeed 
    love.graphics.setFont(font_menu);
    TEsound.stop("back");
    TEsound.play("gameover.mp3",{},0.5);
  end



   if (score+1) % 11 == 0  and not interval_updated then --now , this game is not an easy peasy , we've got to pump it up xD
      spawn_interval = spawn_interval - 0.15
      enemy_damage = enemy_damage + 50
      if spawn_interval < 0.1 then
        print("YOU WON , GOD DAMN!!") --                              ~_~
        spawn_interval = 1
      end
      interval_updated = true
   end



   checkbounds() -- checki if player is not ourside any bounds


 end    --  YEAH!!!!, ALL THIS TIME WE WERE INSIDE THE "RUNNING" GAME STATE




 if game_state == "started" then

        --NO WORK TO DO 
 end

 if game_state == "paused" then
        --NO WORK TO DO 
 end

 if game_state == "gameover" then
        --NO WORK TO DO 
 end



   TEsound.cleanup() --NEEDS TO BE CALLED
 
 
end  --END OF THE UPDATE FUNCTION   





function checkbounds() --checking player bounds

  if pos_x > max_player_x then pos_x=max_player_x end
  if pos_y > max_player_y then pos_y=max_player_y end
  if pos_x < min_player_x then pos_x=min_player_x end
  if pos_y < min_player_y then pos_y=min_player_y end


end




function show_boundingbox() --show bounding box the player bounds

   love.graphics.line(min_player_x,min_player_y,max_player_x,min_player_y)-- upper 
   love.graphics.line(min_player_x,max_player_y,max_player_x,max_player_y) -- lower
   love.graphics.line(min_player_x,min_player_y,min_player_x,max_player_y) -- left
   love.graphics.line(max_player_x,min_player_y,max_player_x,max_player_y) -- right


end



-- some variables, for the nifty intro animation xD
local menu_osc_dir =  0  -- 0 down  , 1 up
local menu_osc=0


-- now , this is the other most important function of Love2d, as the name suggests , this is the DRAWING portion
function love.draw()


   if game_state == "started" then -- the game has just started , play the logo animation

    --image,x,y coord, rotation, scalefactors(x and y)
   love.graphics.draw(menu_logo,180,100+menu_osc,0,1/scale_anim,1/scale_anim)



   -- now truth be told, all these non drawing stuff for the intro animation should have been in the update function , but i'm too lazy to copy paste

   if menu_osc_dir == 0 then
    if 100+menu_osc+1 < 400 then
    menu_osc = menu_osc + 1
  else
    menu_osc_dir = 1    
  end
end
if menu_osc_dir == 1 then
    if 100+menu_osc-1 > 100 then
    menu_osc = menu_osc - 1
  else
    menu_osc_dir = 0   
  end
end

   scale_anim = scale_anim - 0.25
   if scale_anim < 0.75 then 
    scale_anim = 0.75
    love.graphics.print("Press any key to play ! (WASD to move and J to kick DEMONS)",20,550);
  end
   end






   if game_state == "running" then  -- yippie , we are live
   love.graphics.draw(bg,30,100)
   draw_enemies()
   if State==0 then
   stand_anim:draw(pos_x, pos_y)
   elseif State==2 then
   love.graphics.draw(kick_img,moves_list[move_type][moves_list[move_type].iterator],pos_x,pos_y)
 else
   walk_anim:draw(pos_x,pos_y)
   end 
-- enemy_anim:draw(pos_x + 150 , pos_y)   
   fire_anim:draw(490,50)
   fire_anim:draw(210,50)
   love.graphics.setColor(200,200,200)


   --health bar
  love.graphics.rectangle("fill",5,35,max_health/4+10,20+10);
if hit then 
    love.graphics.setColor(255,200,0);    
    hit = false;
  else
   love.graphics.setColor(180,0,0);   
 end
   love.graphics.rectangle("fill",10,40,player_health/4,20);

   --reset colors to default
   love.graphics.setColor(255,255,255);


   --score
     love.graphics.print("Score :"..tostring(score), 400 , 50);
   --love.graphics.print("Mouse pos x:"..tostring(love.mouse.getX()).."  y:"..tostring(love.mouse.getY()), 0 ,20 );
  end
 


    if game_state == "gameover" then --bbye :'(

      love.graphics.print("You DIED !",350,100);
      love.graphics.print("YOUR SCORE : "..tostring(score),250,250);
     
      love.graphics.print("I DO NOT OWN ANY OF THE GRAPHICAL ELEMENTS SHOWN HERE ",10,550);
    end
end

-- THE END , gosh I'm tired of typing
