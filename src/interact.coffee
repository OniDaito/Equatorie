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

# The state of the Equatorie at present and the next stage for it to go to
class EquatorieState

  constructor : (@_activate, @func, @duration=3) ->
    if not @duration?
      @duration = 3.0

  # dt being 0 - 1 progress for this bit
  update : (dt) ->
    @func(dt)

  # called when activated
  activate : () ->
     @_activate() if @_activate?


class EquatorieInteract
  constructor : (@system, @physics, @camera, @white_start, @white_end, @black_start, @black_end, @epicycle, @pointer, @marker, @string_height ) ->

    # Mouse positions
    @mp = new CoffeeGL.Vec2(-1,-1)
    @mpp = new CoffeeGL.Vec2(-1,-1)
    @mpd = new CoffeeGL.Vec2(0,0)

    @picked = false
    @picked_item = undefined
    @dragging = false

    @advance_date  = 0

    # signal for moving the point of interest
    @move_poi = new CoffeeGL.Signal()
    window.EquatorieMovePOI = @move_poi if window?

    @stack = []     # A stack for the states of the system
    @stack_idx = 0  # current stack position

    #@_initGUI()

    @time = 
      start : 0
      dt : 0

  # Takes the current system dt in milliseconds. Can run backwards too!
  # At present the user cant move the items around but we should make that
  # much more explicit. 


  update : (dt) ->
    
    if @stack.length > 0
      if @time.dt / 1000 > @stack[@stack_idx].duration
        @stack[@stack_idx].update(1.0) # Really we could just stop here?
        return
      else if @time.dt < 0
        @stack[@stack_idx].update(0.0)
        return
      else
        # 0 - 1 da progression for stack update
        da = (@time.dt / 1000) / @stack[@stack_idx].duration
        @stack[@stack_idx].update(da)
        @time.dt += dt

    @time.start = new Date().getTime()


  _setPOI : (node) ->
    i0 = node.matrix
    i1 = @camera.m
    i2 = @camera.p.copy()

    vt = new CoffeeGL.Vec3 0,0,0.1
    i2.mult(i1).mult(i0)
    i2.multVec vt

    new CoffeeGL.Vec2 (vt.x+1) / 2 * CoffeeGL.Context.width, CoffeeGL.Context.height - ((vt.y+1) / 2 * CoffeeGL.Context.height)


  # A set of potential functions for moving parts of the Equatorie around
  
  _stateSetPlanetDateInit : () =>
    current_state = @stack[@stack_idx]
    current_state.text = "Set the planet you are looking for and work out the number of days passed since 1392"
    current_state.pos = @_setPOI @epicycle
    @


  _stateSetPlanetDate : (planet, date) =>
    @system.solveForPlanetDate(planet,date)
    @

  _stateCalculateMeanMotusInit : () =>
    current_state = @stack[@stack_idx]
    current_state.text = "Find the mean motus for the body in question."
    if @chosen_planet == "moon_latitude"
      current_state.text = "Subract the true motus of Caput Draconis from the Moon's true motus."

    current_state.pos = @_setPOI @epicycle
    @


  _stateCalculateMeanMotus : (dt) =>
    current_state = @stack[@stack_idx]
    current_state.pos = @_setPOI @epicycle
    @move_poi.dispatch current_state.pos
    @

  
  _stateMoveBlackThreadInit : () =>

    current_state = @stack[@stack_idx]
    current_state.text = "Move the black thread so it runs from the Earth to the Mean Motus"
    current_state.pos = @_setPOI(@black_end)
    mv = @system.state.meanMotusPosition.copy()
    mv.normalize()
    mv.multScalar(10.0)
    current_state.end_interp = new CoffeeGL.Interpolation @black_end.matrix.getPos(), new CoffeeGL.Vec3(mv.x, @string_height, mv.y) 
    current_state.start_interp = new CoffeeGL.Interpolation @black_start.matrix.getPos(), new CoffeeGL.Vec3(0, @string_height, 0) 


  _stateMoveBlackThread : (dt) =>
    # Black to Centre and mean motus  
    # Hold an interpolation object on the state in question

    current_state = @stack[@stack_idx]
    @black_start.matrix.setPos current_state.start_interp.set dt
    @black_end.matrix.setPos current_state.end_interp.set dt

    @physics.postMessage {cmd : "black_start_move", data: @black_start.matrix.getPos() }
    @physics.postMessage {cmd : "black_end_move", data: @black_end.matrix.getPos() }

    current_state.pos = @_setPOI @black_end
    @move_poi.dispatch current_state.pos

    @

  _stateMoveWhiteThreadInit : () =>

    current_state = @stack[@stack_idx]
    current_state.text = "Move the white thread so it runs from the Equant, parallel to the black thread"

    eq = @system.state.equantPosition
    pv = @system.state.parallelPosition
    pv.sub(eq)
    pv.normalize()
    pv.multScalar(10.0)
    pv.add(eq)

    current_state.end_interp = new CoffeeGL.Interpolation @white_end.matrix.getPos(), new CoffeeGL.Vec3(pv.x, @string_height, pv.y) 

    eq = @system.state.equantPosition
    current_state.start_interp = new CoffeeGL.Interpolation @white_start.matrix.getPos(), new CoffeeGL.Vec3(eq.x,@string_height,eq.y) 


  _stateMoveWhiteThread : (dt) =>
  
    current_state = @stack[@stack_idx]
    @white_start.matrix.setPos current_state.start_interp.set dt
    @white_end.matrix.setPos current_state.end_interp.set dt
  
    @physics.postMessage {cmd : "white_start_move", data: @white_start.matrix.getPos() }
    @physics.postMessage {cmd : "white_end_move", data: @white_end.matrix.getPos() }

    current_state.pos = @_setPOI @white_end
    @move_poi.dispatch current_state.pos

  _stateMoveWhiteThreadMoonInit : () =>

    current_state = @stack[@stack_idx]
    current_state.text = "Move the white thread so one end is over the equant and the other runs across the label. The equant is 180 degrees from the deferent."


    pv = @system.state.pointerPoint.copy()
    pv.sub @system.state.equantPosition
    pv.normalize()
    pv.multScalar(10.0)
    pv.add @system.state.equantPosition
    pv = new CoffeeGL.Vec3 pv.x,@string_height,pv.y

    current_state.end_interp = new CoffeeGL.Interpolation @white_end.matrix.getPos(), pv

    eq = @system.state.equantPosition
    current_state.start_interp = new CoffeeGL.Interpolation @white_start.matrix.getPos(), new CoffeeGL.Vec3(eq.x,@string_height,eq.y) 

  _stateMoveWhiteThreadMoon : (dt) =>
  
    current_state = @stack[@stack_idx]

    @white_start.matrix.setPos current_state.start_interp.set dt
    @white_end.matrix.setPos current_state.end_interp.set dt
  
    @physics.postMessage {cmd : "white_start_move", data: @white_start.matrix.getPos() }
    @physics.postMessage {cmd : "white_end_move", data: @white_end.matrix.getPos() }

    current_state.pos = @_setPOI @white_end
    @move_poi.dispatch current_state.pos

    @

  _stateMoveWhiteThreadSunInit : () =>
    current_state = @stack[@stack_idx]
    current_state.text = "Move the white thread so it runs parallel to the black thread from the Sun's equant point."
    ev = new CoffeeGL.Vec3 @system.state.equantPosition.x, @string_height, @system.state.equantPosition.y
    current_state.end_interp = new CoffeeGL.Interpolation @white_end.matrix.getPos(), ev

  
    pv = @system.state.parallelPosition.copy()
    pv.sub @system.state.equantPosition
    pv.normalize()
    pv.multScalar(10.0)
    pv.add @system.state.equantPosition
    pv = new CoffeeGL.Vec3 pv.x,@string_height,pv.y

    current_state.start_interp = new CoffeeGL.Interpolation @white_start.matrix.getPos(), pv


  _stateMoveWhiteThreadSun : (dt) =>

    current_state = @stack[@stack_idx]

    current_state.pos = @_setPOI  @white_end
    @move_poi.dispatch current_state.pos

    @white_start.matrix.setPos current_state.start_interp.set dt
    @white_end.matrix.setPos current_state.end_interp.set dt
    @physics.postMessage {cmd : "white_start_move", data: @white_start.matrix.getPos() }
    @physics.postMessage {cmd : "white_end_move", data: @white_end.matrix.getPos() }

    @


  _stateMoveBlackThreadSunInit : () =>

    current_state = @stack[@stack_idx]
    current_state.text = "Move the black thread so it crosses the white thread at the Sun's eccentric circle."

    pv = @system.state.sunCirclePoint.copy()
    pv.normalize()
    pv.multScalar(10.0)
    pv = new CoffeeGL.Vec3 pv.x,@string_height,pv.y
    current_state.end_interp = new CoffeeGL.Interpolation @white_start.matrix.getPos(), pv


  _stateMoveBlackThreadSun : (dt) =>
    current_state = @stack[@stack_idx]
    @black_end.matrix.setPos current_state.end_interp.set dt
    
    current_state.pos = @_setPOI @black_end
    @move_poi.dispatch current_state.pos

    @physics.postMessage {cmd : "black_end_move", data: @black_end.matrix.getPos() }
    @

  
  _stateMoveEpicycleInit : () =>
    current_state = @stack[@stack_idx]
    current_state.text = "Move the epicycle so its common centre deferent is over the deferent point."

    if @chosen_planet == "moon"
          current_state.text += " The Moon has a moving deferent centre."

    d = @system.state.deferentPosition
    c = @system.state.basePosition
    v = @system.state.parallelPosition
    dr = @system.state.deferentAngle
    if @chosen_planet == "mercury"
      dr = @system.state.mercuryDeferentAngle
    e = @system.state.epicyclePrePosition
    
    current_state.pos_interp = new CoffeeGL.Interpolation @epicycle.matrix.getPos(), new CoffeeGL.Vec3 e.x,0,e.y
    current_state.rot_interp = new CoffeeGL.Interpolation 0, -90-dr


  _stateMoveEpicycle : (dt) =>

    current_state = @stack[@stack_idx]

    @epicycle.matrix.identity()
    @epicycle.matrix.translate current_state.pos_interp.set dt
    @epicycle.matrix.rotate new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad current_state.rot_interp.set dt
    
    @marker.matrix.identity()

    if @chosen_planet == "mercury"
      @marker.matrix.translate(new CoffeeGL.Vec3(@system.state.mercuryDeferentPosition.x,0.4,@system.state.mercuryDeferentPosition.y))
    else if @chosen_planet in ["mars","venus","jupiter","saturn","moon"]
      @marker.matrix.translate(new CoffeeGL.Vec3(@system.state.deferentPosition.x,0.4,@system.state.deferentPosition.y))
    
    current_state.pos = @_setPOI @marker
    @move_poi.dispatch current_state.pos

    @

  _stateRotateEpicycleInit : () =>
    current_state = @stack[@stack_idx]
    current_state.text = "Rotate the epicycle until it's centre is over the white string"
    
    if @chosen_planet == "moon"
      current_state.text = "Rotate the epicycle until it's centre is over the black string"

    current_state.rot_interp = new CoffeeGL.Interpolation 0, @system.state.epicycleRotation


  _stateRotateEpicycle : (dt) =>

    # Now rotate the epicycle around the deferent till it reaches the white line      
    current_state = @stack[@stack_idx]

    #@epicycle.matrix.identity()
    v1 = @system.state.deferentPosition
    if @chosen_planet == "mercury"
      v1 = @system.state.mercuryDeferentPosition

    v2 = CoffeeGL.Vec2.sub @system.state.epicyclePrePosition, v1
    
    
    tmatrix = new CoffeeGL.Matrix4()
    fmatrix = new CoffeeGL.Matrix4()

    deferentAngle = @system.state.deferentAngle
    if @chosen_planet == "mercury"
      deferentAngle = @system.state.mercuryDeferentAngle
 
     
    tmatrix.translate new CoffeeGL.Vec3(v2.x,0,v2.y)
    tmatrix.rotate new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad -90-deferentAngle

    fmatrix.translate new CoffeeGL.Vec3(v1.x,0,v1.y)
    fmatrix.rotate new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad current_state.rot_interp.set dt

    @epicycle.matrix.copyFrom fmatrix.mult tmatrix 

    cp = @system.state.epicyclePosition
    @marker.matrix.identity()
    @marker.matrix.translate(new CoffeeGL.Vec3(cp.x,0.0,cp.y))

    current_state.pos = @_setPOI @epicycle
    @move_poi.dispatch current_state.pos
  
    @

  _stateRotateMeanAuxInit : () =>
    current_state = @stack[@stack_idx]
    current_state.text = "Rotate the label till it is aligned with the white string."

    if @chosen_planet == "moon"
      current_state.text =  "Rotate the label till it is aligned with the black string."


    current_state.rot_interp = new CoffeeGL.Interpolation 0, @system.state.meanAux

  _stateRotateMeanAux : (dt) =>
    current_state = @stack[@stack_idx]

    @pointer.matrix.identity()
    @pointer.matrix.rotate new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad current_state.rot_interp.set dt

    current_state.pos = @_setPOI @epicycle
    @move_poi.dispatch current_state.pos

    @

  _stateRotateLabelInit : () =>
    current_state = @stack[@stack_idx]
    current_state.text = "Rotate the label by the Mean Argument"
    current_state.rot_interp = new CoffeeGL.Interpolation 0, @system.state.pointerAngle

  _stateRotateLabel : (dt) =>

    current_state = @stack[@stack_idx]

    @pointer.matrix.identity()
    @pointer.matrix.rotate new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad @system.state.meanAux + current_state.rot_interp.set dt

    cp = @system.state.pointerPoint
    @marker.matrix.identity()
    @marker.matrix.translate(new CoffeeGL.Vec3(cp.x,0.6,cp.y))

    current_state.pos = @_setPOI @marker
    @move_poi.dispatch current_state.pos

    @


  _stateMoveBlackStringFinalInit : () =>
    current_state = @stack[@stack_idx]
    current_state.text = "Move the black string till it meets the point on the label. Read off the true place where the string crosses the limb"
    mv = new CoffeeGL.Vec3 @system.state.pointerPoint.x,0, @system.state.pointerPoint.y
    mv.normalize()
    mv.multScalar(10.0)
    mv.y = @string_height
    current_state.end_interp = new CoffeeGL.Interpolation @black_end.matrix.getPos(), mv

  _stateMoveBlackStringFinal : (dt) =>
    current_state = @stack[@stack_idx]
    @black_end.matrix.setPos current_state.end_interp.set dt
    @physics.postMessage {cmd : "black_end_move", data: @black_end.matrix.getPos() }

    current_state.pos = @_setPOI @black_end
    @move_poi.dispatch current_state.pos

    @

  _stateMoveBlackStringLatitudeInit : () =>

    current_state = @stack[@stack_idx]

    current_state.text = "Move the black string so it is perpendicular to the Alhudda line and cutting the rim at the spot marked by the previous value."
    
    s = new CoffeeGL.Vec3(@system.state.moonLatitudeLeft.x, 0, @system.state.moonLatitudeLeft.y)
    e = new CoffeeGL.Vec3(@system.state.moonLatitudeRight.x, 0, @system.state.moonLatitudeRight.y)

    # stretch the string
    l = s.dist e
    s.x = s.x - (6-l/2)
    e.x = e.x + (6-l/2)

    s.y = @string_height
    e.y = @string_height


    
    current_state.start_interp = new CoffeeGL.Interpolation @black_start.matrix.getPos(), s
    current_state.end_interp = new CoffeeGL.Interpolation @black_end.matrix.getPos(), e


  _stateMoveBlackStringLatitude : (dt) =>

    current_state = @stack[@stack_idx]

    @black_start.matrix.setPos current_state.start_interp.set dt
    @black_end.matrix.setPos current_state.end_interp.set dt

    current_state.pos = @_setPOI @black_end
    @move_poi.dispatch current_state.pos

    @physics.postMessage {cmd : "black_start_move", data: @black_start.matrix.getPos() }
    @physics.postMessage {cmd : "black_end_move", data: @black_end.matrix.getPos() }

    @


  addStates : (planet, date) ->
    @stack = []
    @stack.push new EquatorieState @_stateSetPlanetDateInit, () => do (planet,date) => @_stateSetPlanetDate(planet,date)

    if planet in ['mars','venus','jupiter','saturn','mercury']
      
      @stack.push new EquatorieState @_stateCalculateMeanMotusInit, @_stateCalculateMeanMotus
      @stack.push new EquatorieState @_stateMoveBlackThreadInit, @_stateMoveBlackThread 
      @stack.push new EquatorieState @_stateMoveWhiteThreadInit, @_stateMoveWhiteThread 
      @stack.push new EquatorieState @_stateMoveEpicycleInit, @_stateMoveEpicycle
      @stack.push new EquatorieState @_stateRotateEpicycleInit, @_stateRotateEpicycle
      @stack.push new EquatorieState @_stateRotateMeanAuxInit, @_stateRotateMeanAux 
      @stack.push new EquatorieState @_stateRotateLabelInit, @_stateRotateLabel 
      @stack.push new EquatorieState @_stateMoveBlackStringFinalInit, @_stateMoveBlackStringFinal

    else if planet == 'moon'
      @stack.push new EquatorieState @_stateCalculateMeanMotusInit, @_stateCalculateMeanMotus
      @stack.push new EquatorieState @_stateMoveBlackThreadInit, @_stateMoveBlackThread
      @stack.push new EquatorieState @_stateMoveEpicycleInit, @_stateMoveEpicycle
      @stack.push new EquatorieState @_stateRotateEpicycleInit, @_stateRotateEpicycle
      @stack.push new EquatorieState @_stateRotateMeanAuxInit, @_stateRotateMeanAux
      @stack.push new EquatorieState @_stateRotateLabelInit, @_stateRotateLabel
      @stack.push new EquatorieState @_stateMoveWhiteThreadMoonInit, @_stateMoveWhiteThreadMoon

    else if planet == "moon_latitude"
      @stack.push new EquatorieState @_stateCalculateMeanMotusInit, @_stateCalculateMeanMotus
      @stack.push new EquatorieState @_stateMoveBlackStringLatitudeInit, @_stateMoveBlackStringLatitude

    else if planet == "sun"
      @stack.push new EquatorieState @_stateCalculateMeanMotusInit, @_stateCalculateMeanMotus
      @stack.push new EquatorieState @_stateMoveBlackThreadInit, @_stateMoveBlackThread
      @stack.push new EquatorieState @_stateMoveWhiteThreadSunInit, @_stateMoveWhiteThreadSun
      @stack.push new EquatorieState @_stateMoveBlackThreadSunInit, @_stateMoveBlackThreadSun

  # reset all the things

  reset : () ->
    # Clear the stack
    @stack = []
    @stack_idx = 0
    @system.reset()
    @marker.matrix.identity()
    @epicycle.matrix.identity()
    @pointer.matrix.identity()

    # Move the strings back
    @white_start.matrix.identity().translate new CoffeeGL.Vec3 2,@string_height,2
    @white_end.matrix.identity().translate new CoffeeGL.Vec3 -2,@string_height,-2
    @black_start.matrix.identity().translate new CoffeeGL.Vec3 -2,@string_height,2
    @black_end.matrix.identity().translate new CoffeeGL.Vec3 -4,@string_height,2

    # Move the camera back

    @camera.pos = new CoffeeGL.Vec3 0,0,10
    @camera.look = new CoffeeGL.Vec3 0,0,0
    @camera.up = new CoffeeGL.Vec3 0,1,0
    @camera.rotateFocal new CoffeeGL.Vec3(1,0,0), CoffeeGL.degToRad -25

    @physics.postMessage { cmd: "reset" }

  # Called when the button is pressed in dat.gui. Solve for the chosen planet
  solveForPlanet : (planet, date) ->

    # Clear the stack
    @reset()
    @addStates(planet,date)

    for s in [0..@stack.length-1]
      @stack_idx = s
      state = @stack[s]
      state.activate()
      state.update 1.0


  onMouseDown : (event) ->
    @mp.x = event.mouseX
    @mp.y = event.mouseY
    @ray = @camera.castRay @mp.x, @mp.y
    
    @mdown = true

    if not @picked
      @camera.onMouseDown(event)
    else
      @dragging = true

  onMouseMove : (event) ->
    @mpp.x = @mp.x
    @mpp.y = @mp.y

    @mp.x = event.mouseX
    @mp.y = event.mouseY

    @mpd.x = @mp.x - @mpp.x
    @mpd.y = @mp.y - @mpp.y

    if @dragging

      tray = @camera.castRay @mp.x, @mp.y
      d = CoffeeGL.rayPlaneIntersect new CoffeeGL.Vec3(0,@string_height,0), new CoffeeGL.Vec3(0,1,0), @camera.pos, @ray
      dd = CoffeeGL.rayPlaneIntersect new CoffeeGL.Vec3(0,@string_height,0), new CoffeeGL.Vec3(0,1,0), @camera.pos, tray

      p0 = tray.copy()
      p0.multScalar(dd)
      p0.add(@camera.pos)

      p1 = @ray.copy()
      p1.multScalar(d)
      p1.add(@camera.pos)

      p0.y = @string_height
      p1.y = @string_height

      np = CoffeeGL.Vec3.sub(p0,p1)

      @ray.copyFrom(tray)

      if @picked_item != @pointer
        tp = @picked_item.matrix.getPos()
        @picked_item.matrix.setPos( tp.add(np) )

      # Update the phyics webworker thread if strings
      if @picked_item == @white_start
          @physics.postMessage {cmd : "white_start_move", data: @picked_item.matrix.getPos() }
      
      else if @picked_item == @white_end
          @physics.postMessage {cmd : "white_end_move", data: @picked_item.matrix.getPos() }
      
      else if @picked_item == @black_start
          @physics.postMessage {cmd : "black_start_move", data: @picked_item.matrix.getPos() }
      
      else if @picked_item == @black_end
          @physics.postMessage {cmd : "black_end_move", data: @picked_item.matrix.getPos() }

    else
      @camera.onMouseMove(event)


  checkPicked : (p) ->
    
    if @dragging
      return

    @picked = false

    # red, green, blue, white for strings, ws, we, bs, be
    # magenta for epi 1,1,0
    # cyan for pointer 0,1,1
    # Bit shift / mask might be faster here I think

    if p[0] == 255 and p[1] == 0 and p[2] == 0
      @picked_item = @white_start
      @picked = true

    else if p[0] == 0 and p[1] == 255 and p[2] == 0
      @picked_item = @white_end
      @picked = true

    else if p[0] == 0 and p[1] == 0 and p[2] == 255
      @picked_item = @black_start
      @picked = true

    else if p[0] == 255 and p[1] == 255 and p[2] == 255
      @picked_item = @black_end
      @picked = true

    else if p[0] == 255 and p[1] == 255 and p[2] == 0
      @picked_item = @epicycle
      @picked = true

    else if p[0] == 0 and p[1] == 255 and p[2] == 255
      @picked_item = @pointer
      @picked = true
      

  _initGUI : () ->
    # DAT Gui stuff
    # https://gist.github.com/ikekou/5589109
    @datgui =new dat.GUI()
    @datgui.remember(@)
    
    planets = ["mars","venus","jupiter","saturn","mercury","moon","sun","moon_latitude"]
    @chosen_planet = "mars"

    controller = @datgui.add(@,'chosen_planet',planets)
    controller = @datgui.add(@,'solveForCurrentDatePlanet')
    controller = @datgui.add(@,'advance_date',0,730)
    controller.onChange( (value) => 
      @solveForCurrentDatePlanet()
    )

    controller = @datgui.add(@, "stepForward")
    controller = @datgui.add(@, "reset")

    # Shader Controls
    controller = @datgui.add(@pointer,'uAlphaX',0,1)
    controller = @datgui.add(@pointer,'uAlphaY',0,1)

    controller = @datgui.add(@epicycle,'uAlphaX',0,1)
    controller = @datgui.add(@epicycle,'uAlphaY',0,1)

  solveForCurrentDatePlanet : () ->
    date = new Date()
    date.setDate date.getDate() + @advance_date 
    @solveForPlanet(@chosen_planet, date)



  stepForward : () ->

    @time.start = new Date().getTime()

    date = new Date()
    date.setDate date.getDate() + @advance_date 

    if @stack.length == 0
      @addStates @chosen_planet, date
      @stack_idx = 0
    else
      if @stack_idx + 1 < @stack.length
        # Make sure current state has completed
        @stack[@stack_idx].update(1.0)
        @time.dt = 0
        @stack_idx +=1
    
    @stack[@stack_idx].activate()

    # Return data for the JQuery / Bootstrap front end
    rval = {}

    rval.text = @stack[@stack_idx].text if @stack[@stack_idx].text?
    rval.pos = @stack[@stack_idx].pos if @stack[@stack_idx].pos?
    rval

  onMouseOver : (event) ->    
    @mp.x = event.mouseX
    @mp.y = event.mouseY

  onMouseUp : (event) ->
    @mdown = false
    @picked = false
    @dragging = false

  onMouseOut : (event) ->
    @mp.x = @mpp.x = -1
    @mp.y = @mpp.y = -1
    @mpd.x = @mpd.y = 0

    @mdown = false
    @picked = false
    @dragging = false


module.exports = 
  EquatorieInteract : EquatorieInteract