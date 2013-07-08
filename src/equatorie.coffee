###
                       __  .__              ________ 
   ______ ____   _____/  |_|__| ____   ____/   __   \
  /  ___// __ \_/ ___\   __\  |/  _ \ /    \____    /
  \___ \\  ___/\  \___|  | |  (  <_> )   |  \ /    / 
 /____  >\___  >\___  >__| |__|\____/|___|  //____/  .co.uk
      \/     \/     \/                    \/         
                                              CoffeeGL
                                              Benjamin Blundell - ben@section9.co.uk
                                              http://www.section9.co.uk

This software is released under Creative Commons Attribution Non-Commercial Share Alike
http://creativecommons.org/licenses/by-nc-sa/3.0/

###


{EquatorieSystem} = require './system'
{EquatorieString} = require './string'


class Equatorie

  init : () =>
    
    # All nodes to be drawn
    @top_node = new CoffeeGL.Node()

    @string_height = 0.4

    # Nodes for the picking
    @pickable = new CoffeeGL.Node()
    @fbo_picking = new CoffeeGL.Fbo()
    @ray = new CoffeeGL.Vec3(0,0,0)
    @picked = undefined

    # Nodes being drawn with the basic shader
    @basic_nodes = new CoffeeGL.Node()

    # Mouse positions
    @mp = new CoffeeGL.Vec2(-1,-1)
    @mpp = new CoffeeGL.Vec2(-1,-1)
    @mpd = new CoffeeGL.Vec2(0,0)
    @mdown = false

    @system = new EquatorieSystem()

    r0 = new CoffeeGL.Request ('../shaders/basic.glsl')
    r0.get (data) =>
      @shader_basic = new CoffeeGL.Shader(data, {"uColour" : "uColour"})

      
      @top_node.add @basic_nodes
      @basic_nodes.shader = @shader_basic


      @deferent.shader = @shader_basic
      @deferent.uColour = new CoffeeGL.Colour.RGBA(1.0,0.0,0.0,1.0)

      r1 = new CoffeeGL.Request ('../shaders/basic_lighting.glsl')
      
      r1.get (data) =>
        @shader = new CoffeeGL.Shader(data, {"uAmbientLightingColor" : "uAmbientLightingColor"})
      
        r2 = new CoffeeGL.Request('../models/equatorie.js')

        r2.get (data) =>
          @g = new CoffeeGL.JSONModel(data) 
          @top_node.add(@g)

          # Should be three children nodes with this model. Attach the shaders
          
          @pointer  = @g.children[0]
          @epicycle = @g.children[1]
          @base     = @g.children[2]

          @pointer.shader   = @shader_basic
          @epicycle.shader  = @shader_basic
          @base.shader      = @shader

          @base.uAmbientLightingColor = new CoffeeGL.Colour.RGBA(0.0,1.0,1.0,1.0)

          @pointer.uColour = new CoffeeGL.Colour.RGBA(1.0,1.0,0.0,1.0)
          @epicycle.uColour = new CoffeeGL.Colour.RGBA(0.6,0.6,0.0,1.0)

          # Remove the pointer and add it as a child of the Epicycle
          @g.remove @pointer
          @epicycle.add @pointer

          # Rotate the Base so the Sign of Aries is in the right place
          q = new CoffeeGL.Quaternion()
          q.fromAxisAngle(new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad(-90.0))

          @base.matrix.mult q.getMatrix4() 

          r3 = new CoffeeGL.Request('../shaders/picking.glsl')
          r3.get (data) =>
            @shader_picker = new CoffeeGL.Shader(data, {"uPickingColour" : "uPickingColour"})
            @pickable.shader = @shader_picker


    # Points on the surface of the Equatorie
    cube = new CoffeeGL.Shapes.Cuboid new CoffeeGL.Vec3 0.2,0.2,0.2
    @deferent = new CoffeeGL.Node cube
    @top_node.add @deferent

    @equant = new CoffeeGL.Node cube
    @top_node.add @equant

    @c = new CoffeeGL.Camera.MousePerspCamera(new CoffeeGL.Vec3(0,0,25))
    @top_node.add(@c)
    @pickable.add(@c)

    @light = new CoffeeGL.Light.PointLight(new CoffeeGL.Vec3(0.0,5.0,25.0), new CoffeeGL.Colour.RGB(1.0,1.0,1.0) );
    @light2 = new CoffeeGL.Light.PointLight(new CoffeeGL.Vec3(0.0,15.0,5.0), new CoffeeGL.Colour.RGB(1.0,1.0,1.0) );

    @top_node.add(@light)
    @top_node.add(@light2)

    GL.enable(GL.CULL_FACE)
    GL.cullFace(GL.BACK)
    GL.enable(GL.DEPTH_TEST)


    # DAT Gui stuff
    # https://gist.github.com/ikekou/5589109
    g=new dat.GUI()
    g.remember(@)
    
    planets = ["mars","venus","jupiter","saturn"]
    @chosen_planet = "mars"

    controller = g.add(@system,'mean_argument',0,360)
    controller = g.add(@system,'mean_motus',0,360)
    controller = g.add(@,'chosen_planet',planets)

    # Add Strings
    @white_string = new EquatorieString 8.0, 0.08, 20
    @black_string = new EquatorieString 8.0, 0.08, 20
    
    @top_node.add @white_string
    @top_node.add @black_string

    @white_start = new CoffeeGL.Node cube
    @pickable.add @white_start
    @white_start.matrix.translate new CoffeeGL.Vec3 2,@string_height,2
    @white_start.uPickingColour = new CoffeeGL.Colour.RGBA(1.0,0.0,0.0,1.0)

    @white_end = new CoffeeGL.Node cube
    @pickable.add @white_end
    @white_end.matrix.translate new CoffeeGL.Vec3 -2,@string_height,-2
    @white_end.uPickingColour = new CoffeeGL.Colour.RGBA(1.0,1.0,0.0,1.0)

    @black_start = new CoffeeGL.Node cube
    @pickable.add @black_start
    @black_start.matrix.translate new CoffeeGL.Vec3 -2,@string_height,2
    @black_start.uPickingColour = new CoffeeGL.Colour.RGBA(0.0,1.0,1.0,1.0)

    @black_end = new CoffeeGL.Node cube
    @pickable.add @black_end
    @black_end.matrix.translate new CoffeeGL.Vec3 -4,@string_height,2
    @black_end.uPickingColour = new CoffeeGL.Colour.RGBA(1.0,1.0,1.0,1.0)

    @basic_nodes.add(@white_string).add(@black_string)
    @basic_nodes.add(@white_start).add(@white_end)
    @basic_nodes.add(@black_start).add(@black_end)

    @white_string.uColour = new CoffeeGL.Colour.RGBA(0.9,0.9,0.9,1.0)
    @black_string.uColour = new CoffeeGL.Colour.RGBA(0.1,0.1,0.1,1.0)
    @white_start.uColour = new CoffeeGL.Colour.RGBA(0.9,0.2,0.2,0.8)
    @white_end.uColour = new CoffeeGL.Colour.RGBA(0.9,0.2,0.2,0.8)

    # Launch physics web worker
    @physics = new Worker '/js/physics.js'
    @physics.onmessage = @onPhysicsEvent
    @physics.postMessage { cmd: "startup" }


    # Register for mouse events
    CoffeeGL.Context.mouseDown.add @onMouseDown, @
    CoffeeGL.Context.mouseOver.add @onMouseOver, @
    CoffeeGL.Context.mouseOut.add @onMouseOut, @
    CoffeeGL.Context.mouseMove.add @onMouseMove, @
    CoffeeGL.Context.mouseUp.add @onMouseUp, @

    # Remove the camera mouse event - we want control over that
    CoffeeGL.Context.mouseMove.del @c.onMouseMove, @c
    CoffeeGL.Context.mouseDown.del @c.onMouseDown, @c


  update : (dt) =>
  
    @angle = dt * 0.001 * CoffeeGL.degToRad(20.0)
    if @angle >= CoffeeGL.PI * 2
      @angle = 0
    m = new CoffeeGL.Quaternion()
    m.fromAxisAngle(new CoffeeGL.Vec3(0,1,0), @angle)
    m.transVec3(@light.pos)

    # Calculate the Deferent Centre
    
    [x,y] = @system.calculateDeferentPosition(@chosen_planet)
    @deferent.matrix.identity()
    @deferent.matrix.translate new CoffeeGL.Vec3 x,0.2,y

    [x,y] = @system.calculateEpicyclePosition(@chosen_planet)
    @epicycle?.matrix.identity()
    @epicycle?.matrix.translate new CoffeeGL.Vec3 x,0,y


    @pointer?.matrix.identity()
    q = new CoffeeGL.Quaternion()
    q.fromAxisAngle(new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad(@system.mean_argument))

    @pointer?.matrix.mult q.getMatrix4()
   
    @

  # update the physics - each body in the string needs to have its position and orientation updated
  updatePhysics : (data) ->
    @white_string.update data.white
    @black_string.update data.black

  onMouseDown : (event) ->
    console.log event
    @mp.x = event.mouseX
    @mp.y = event.mouseY
    @ray = @c.castRay @mp.x, @mp.y
    
    if @picked?
        @mdown = true

    if not @mdown
      @c.onMouseDown(event)

  onMouseMove : (event) ->
    @mpp.x = @mp.x
    @mpp.y = @mp.y

    @mp.x = event.mouseX
    @mp.y = event.mouseY

    @mpd.x = @mp.x - @mpp.x
    @mpd.y = @mp.y - @mpp.y

   
    if @mdown and @picked?
      tray = @c.castRay @mp.x, @mp.y
      d = CoffeeGL.rayPlaneIntersect new CoffeeGL.Vec3(0,@string_height,0), new CoffeeGL.Vec3(0,1,0), @c.pos, @ray
      dd = CoffeeGL.rayPlaneIntersect new CoffeeGL.Vec3(0,@string_height,0), new CoffeeGL.Vec3(0,1,0), @c.pos, tray

      p0 = tray.copy()
      p0.multScalar(dd)
      p0.add(@c.pos)

      p1 = @ray.copy()
      p1.multScalar(d)
      p1.add(@c.pos)

      p0.y = @string_height
      p1.y = @string_height

      np = CoffeeGL.Vec3.sub(p0,p1)

      @ray.copyFrom(tray)

      @picked.matrix.translate(np)

      # Update the phyics webworker thread 
      if @picked == @white_start
          @physics.postMessage {cmd : "white_start_move", data: @picked.matrix.getPos() }
      
      else if @picked == @white_end
          @physics.postMessage {cmd : "white_end_move", data: @picked.matrix.getPos() }
      
      else if @picked == @black_start
          @physics.postMessage {cmd : "black_start_move", data: @picked.matrix.getPos() }
      
      else if @picked == @black_end
          @physics.postMessage {cmd : "black_end_move", data: @picked.matrix.getPos() }

    else
      @c.onMouseMove(event)

    

  onMouseOver : (event) ->    
    @mp.x = event.mouseX
    @mp.y = event.mouseY

  onMouseUp : (event) ->
    @mdown = false

  onMouseOut : (event) ->
    @mp.x = @mpp.x = -1
    @mp.y = @mpp.y = -1
    @mpd.x = @mpd.y = 0

    @mdown = false
    @picked = undefined

  onPhysicsEvent : (event) =>
    switch event.data.cmd
      when "physics" then @updatePhysics event.data.data
      when "ping" then console.log "Physics Ping: " + event.data.data
      else break


  checkPicked : (pixel) ->
    
    @picked = undefined

    if pixel[0] == 255
      if pixel[1] == 255
        if pixel[2] == 255
          #console.log "Black End"
          @picked = @black_end
          #console.log pixel
        else
          #console.log "White end"
          @picked = @white_end
          #console.log pixel
      else
        #console.log "White Start"
        @picked = @white_start
        #console.log pixel
    else if pixel[1] == 255
      #console.log "Black Start"
      @picked = @black_start
      #console.log pixel


  draw : () =>

    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

    @c.update()

    @top_node.draw() if @top_node?
    
    # Draw everything pickable to the pickable FBO
    if @shader_picker?
      @fbo_picking.bind()
      @shader_picker.bind()
      @pickable.draw()
    
      # Cx for picking
      if @mp.y != -1 and @mp.x != -1 and not @mdown
        pixel = new Uint8Array(4);
        GL.readPixels(@mp.x, @fbo_picking.height - @mp.y, 1, 1, GL.RGBA, GL.UNSIGNED_BYTE, pixel)

        @checkPicked pixel
    
      @shader_picker.unbind()
      @fbo_picking.unbind()
    
  
eq = new Equatorie()

cgl = new CoffeeGL.App('webgl-canvas', eq, eq.init, eq.draw, eq.update)