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

###


{EquatorieSystem} = require './system'
{EquatorieString} = require './string'
{loadAssets} = require './load'
{EquatorieInteract} = require './interact'

class Equatorie

  init : () =>
    
    # All nodes to be drawn
    @top_node = new CoffeeGL.Node()

    @string_height = 0.4
    # Nodes for the picking
    @pickable = new CoffeeGL.Node()
    @fbo_picking = new CoffeeGL.Fbo()
    @ray = new CoffeeGL.Vec3(0,0,0)

    @advance_date = 0

    # Nodes being drawn with the basic shader
    @basic_nodes = new CoffeeGL.Node()

    # Mouse position
    @mp = new CoffeeGL.Vec2(-1,-1)
  
    @system = new EquatorieSystem()

    @ready = false

    @loaded = new CoffeeGL.Signal()

    # test test
    
    @system._calculateDate(new Date ("January 1, 1393 00:00:00") )
    @system._setPlanet("mars")   
    @system._calculateDeferentAngle()
    console.log @system._calculateDeferentPosition()

    @system._setPlanet("venus")   
    @system._calculateDeferentAngle()
    console.log @system._calculateDeferentPosition()

    @system._setPlanet("jupiter")   
    @system._calculateDeferentAngle()
    console.log @system._calculateDeferentPosition()

    @system._setPlanet("saturn")   
    @system._calculateDeferentAngle()
    console.log @system._calculateDeferentPosition()

    @system._setPlanet("mercury")   
    @system._calculateDeferentAngle()
    @system._calculateDeferentPosition()
    console.log @system.state.deferentPosition


    @system.reset()

    # Function called when everything is loaded
    f = () =>

      console.log "Loaded Assets"

      @top_node.add @basic_nodes
      @basic_nodes.shader = @shader_basic   
      @marker.shader = @shader_basic
  
      @top_node.add(@equatorie_model)

      # Should be five children nodes with this model. Attach the shaders
      
      @base     = @equatorie_model.children[3]
      @epicycle = @equatorie_model.children[0]
      @pointer  = @equatorie_model.children[4]
      @rim      = @equatorie_model.children[2]
      @plate    = @equatorie_model.children[1]

      # Create the node for shiny ansio things
      @shiny =  new CoffeeGL.Node()
      @equatorie_model.add @shiny
      @equatorie_model.remove @epicycle
      @equatorie_model.remove @pointer
      @equatorie_model.remove @rim
      @equatorie_model.remove @plate
      @equatorie_model.remove @base

      # Create the tangents
      @_setTangents @pointer.geometry
      @_setTangents @epicycle.geometry
      @_setTangents @rim.geometry
      @_setTangents @plate.geometry
      @_setTangents @base.geometry

      @shiny.shader = @shader_aniso
      @shiny.add @epicycle
      @shiny.add @rim
      @shiny.add @plate
      @shiny.add @base

      # Add the normal textures
      @pointer.add @pointer_normal
      @rim.add @rim_normal
      @plate.add @plate_normal
      @epicycle.add @epicycle_normal
      @base.add @base_normal

      @shiny.uSamplerNormal = 1 # set for the first texture unit

      # Add normal textures

    
      @base.uAmbientLightingColor = new CoffeeGL.Colour.RGBA(1.0,1.0,0.8,1.0)
      @base.uSpecColour = new CoffeeGL.Colour.RGBA(0.5,0.5,0.5,1.0)
      @base.uAlphaX = 0.05
      @base.uAlphaY = 0.05

      @epicycle.uAmbientLightingColor = new CoffeeGL.Colour.RGBA(0.1,0.1,0.1,1.0)
      @epicycle.uSpecColour = new CoffeeGL.Colour.RGBA(1.0,0.9,0.8,1.0)
      @epicycle.uAlphaX = 0.4
      @epicycle.uAlphaY = 0.28

      @pointer.uAmbientLightingColor = new CoffeeGL.Colour.RGBA(0.1,0.1,0.1,1.0)
      @pointer.uSpecColour = new CoffeeGL.Colour.RGBA(1.0,0.9,0.9,1.0)
      @pointer.uAlphaX = 0.2
      @pointer.uAlphaY = 0.1

      @epicycle.uPickingColour = new CoffeeGL.Colour.RGBA 1.0,1.0,0.0,1.0
      @pointer.uPickingColour = new CoffeeGL.Colour.RGBA 0.0,1.0,1.0,1.0
      @pickable.add @epicycle

      # Remove the pointer and add it as a child of the Epicycle
      @equatorie_model.remove @pointer
      @epicycle.add @pointer

      # Rotate the Base so the Sign of Aries is in the right place
      q = new CoffeeGL.Quaternion()
      q.fromAxisAngle(new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad(-90.0))

      @base.matrix.mult q.getMatrix4() 
        
      # Set the pickable shader for the pickables
      @pickable.shader = @shader_picker
            
      @top_node.add @basic_nodes
      @basic_nodes.shader = @shader_basic
      @marker.shader = @shader_basic

      # Launch physics web worker
      @physics = new Worker '/js/physics.js'
      @physics.onmessage = @onPhysicsEvent
      @physics.postMessage { cmd: "startup" }

      # Fire up the interaction class that takes over behaviour from here
      # This class takes quite a lot of objects so its not ideal
      @interact = new EquatorieInteract(@system, @physics, @c, @white_start, @white_end, @black_start, @black_end, @epicycle, @pointer, @marker, @string_height )

      # Register for mouse events
      CoffeeGL.Context.mouseDown.add @interact.onMouseDown, @interact
      CoffeeGL.Context.mouseOver.add @interact.onMouseOver, @interact
      CoffeeGL.Context.mouseOut.add @interact.onMouseOut, @interact
      CoffeeGL.Context.mouseMove.add @interact.onMouseMove, @interact
      CoffeeGL.Context.mouseUp.add @interact.onMouseUp, @interact

      CoffeeGL.Context.mouseOver.add @onMouseOver, @
      CoffeeGL.Context.mouseOut.add @onMouseOut, @
      CoffeeGL.Context.mouseMove.add @onMouseMove, @

      # Remove the camera mouse event - we want control over that
      CoffeeGL.Context.mouseMove.del @c.onMouseMove, @c
      CoffeeGL.Context.mouseDown.del @c.onMouseDown, @c

      @ready = true

    

    # Fire off the loader with the signal
    @loaded.addOnce f, @
    loadAssets @, @loaded

    # Use today for the apsides precession

    date = new Date()
    
    # Our basic marker - this is part of our interaction
    cube = new CoffeeGL.Shapes.Cuboid new CoffeeGL.Vec3 0.2,0.2,0.2
    cube2 = new CoffeeGL.Shapes.Cuboid new CoffeeGL.Vec3 0.01,0.5,0.01
    @marker = new CoffeeGL.Node cube2
    @marker.uColour = new CoffeeGL.Colour.RGBA(0.0,1.0,1.0,1.0)
    @top_node.add @marker

    @c = new CoffeeGL.Camera.TouchPerspCamera(new CoffeeGL.Vec3(0,0,25))
    @top_node.add(@c)
    @pickable.add(@c)

    # Lights

    @light = new CoffeeGL.Light.PointLight(new CoffeeGL.Vec3(0.0,5.0,25.0), new CoffeeGL.Colour.RGB(1.0,1.0,1.0) );
    @light2 = new CoffeeGL.Light.PointLight(new CoffeeGL.Vec3(0.0,15.0,5.0), new CoffeeGL.Colour.RGB(1.0,1.0,1.0) );

    @top_node.add(@light)
    @top_node.add(@light2)

    # OpenGL Constants
    GL.enable(GL.CULL_FACE)
    GL.cullFace(GL.BACK)
    GL.enable(GL.DEPTH_TEST)

    # Add Strings
    @white_string = new EquatorieString 10.0, 0.01, 20
    @black_string = new EquatorieString 10.0, 0.01, 20
    

    @white_start = new CoffeeGL.Node cube
    @pickable.add @white_start
    @white_start.matrix.translate new CoffeeGL.Vec3 2,@string_height,2
    @white_start.uPickingColour = new CoffeeGL.Colour.RGBA(1.0,0.0,0.0,1.0)

    @white_end = new CoffeeGL.Node cube
    @pickable.add @white_end
    @white_end.matrix.translate new CoffeeGL.Vec3 -2,@string_height,-2
    @white_end.uPickingColour = new CoffeeGL.Colour.RGBA(0.0,1.0,0.0,1.0)

    @black_start = new CoffeeGL.Node cube
    @pickable.add @black_start
    @black_start.matrix.translate new CoffeeGL.Vec3 -2,@string_height,2
    @black_start.uPickingColour = new CoffeeGL.Colour.RGBA(0.0,0.0,1.0,1.0)

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

   
  update : (dt) =>
  
    #date = new Date("May 31, 1585 00:00:00")
    if not @ready
      return

    date = new Date()

    @angle = dt * 0.001 * CoffeeGL.degToRad(20.0)
    if @angle >= CoffeeGL.PI * 2
      @angle = 0
    m = new CoffeeGL.Quaternion()
    m.fromAxisAngle(new CoffeeGL.Vec3(0,1,0), @angle)
    m.transVec3(@light.pos)

    @interact.update(dt)

    @

  # update the physics - each body in the string needs to have its position and orientation updated
  updatePhysics : (data) ->
    @white_string.update data.white
    @black_string.update data.black

  
  onPhysicsEvent : (event) =>
    switch event.data.cmd
      when "physics" then @updatePhysics event.data.data
      when "ping" then console.log "Physics Ping: " + event.data.data
      else break


  draw : () =>

    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

    @c.update CoffeeGL.Context.width, CoffeeGL.Context.height

    @top_node.draw() if @top_node?
    
    # Draw everything pickable to the pickable FBO
    if @shader_picker?
      @fbo_picking.bind()
      @fbo_picking.clear()
      @shader_picker.bind()
      @pickable.draw()
    
      # Cx for picking
      if @mp.y != -1 and @mp.x != -1
        pixel = new Uint8Array(4);
        GL.readPixels(@mp.x, @fbo_picking.height - @mp.y, 1, 1, GL.RGBA, GL.UNSIGNED_BYTE, pixel)

        @interact.checkPicked pixel
    
      @shader_picker.unbind()
      @fbo_picking.unbind()


  onMouseMove : (event) ->
    @mp.x = event.mouseX
    @mp.y = event.mouseY


  onMouseOver : (event) ->    
    @mp.x = event.mouseX
    @mp.y = event.mouseY

  onMouseOut : (event) ->
    @mp.x = -1
    @mp.y = -1



  resize : (w,h) ->
    @fbo_picking.resize(w,h)

  _setTangents : (geom) ->
    for face in geom.faces
      [a,b,c] = CoffeeGL.precomputeTangent face.v[0].p, face.v[1].p, face.v[2].p, 
        face.v[0].n, face.v[1].n, face.v[2].n, face.v[0].t, face.v[1].t, face.v[2].t

      face.v[0].tangent = a
      face.v[1].tangent = b
      face.v[2].tangent = c
    @
  
eq = new Equatorie()
cgl = new CoffeeGL.App('webgl-canvas', eq, eq.init, eq.draw, eq.update)

f = () ->
  w = $(window).width();
  h = $(window).height();

  $("#webgl-canvas").attr("width", w)
  $("#webgl-canvas").attr("height", h)

  $("#webgl-canvas").width(w)
  $("#webgl-canvas").height(h)

  cgl.resize(w,h)
  eq.resize(w,h)


$(window).bind("resize", f)
$(window).bind("ready", f)


