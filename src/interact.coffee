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

  constructor : (@name, @func, @duration=3) ->
    if not @duration?
      @duration = 3.0

  # dt being 0 - 1 progress for this bit
  update : (dt) ->
    @func(dt)


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

    @stack = []     # A stack for the states of the system
    @stack_idx = 0  # current stack position

    @_initGUI()

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


  # A set of potential functions for moving parts of the Equatorie around
  
  _stateSetPlanetDate : (planet, date) =>
    @system.solveForPlanetDate(planet,date)

  _stateCalculateMeanMotus : (dt) =>

    @

  _stateMoveBlackThread : (dt) =>
    # Black to Centre and mean motus  
    # Hold an interpolation object on the state in question

    current_state = @stack[@stack_idx]

    if not current_state.end_interp?

      mv = @system.state.meanMotusPosition
      mv.normalize()
      mv.multScalar(10.0)
      current_state.end_interp = new CoffeeGL.Interpolation @black_end.matrix.getPos(), new CoffeeGL.Vec3(mv.x, @string_height, mv.y) 

    if not current_state.start_interp?
      current_state.start_interp = new CoffeeGL.Interpolation @black_start.matrix.getPos(), new CoffeeGL.Vec3(0, @string_height, 0) 

    @black_start.matrix.setPos current_state.start_interp.set dt
    @black_end.matrix.setPos current_state.end_interp.set dt

    @physics.postMessage {cmd : "black_start_move", data: @black_start.matrix.getPos() }
    @physics.postMessage {cmd : "black_end_move", data: @black_end.matrix.getPos() }
    @

  _stateMoveWhiteThread : (dt) =>
  
    current_state = @stack[@stack_idx]

    if not current_state.end_interp?
      eq = @system.state.equantPosition
      pv = @system.state.parallelPosition
      pv.sub(eq)
      pv.normalize()
      pv.multScalar(10.0)
      pv.add(eq)

      current_state.end_interp = new CoffeeGL.Interpolation @white_end.matrix.getPos(), new CoffeeGL.Vec3(pv.x, @string_height, pv.y) 

    if not current_state.start_interp?
    
      eq = @system.state.equantPosition
      current_state.start_interp = new CoffeeGL.Interpolation @white_start.matrix.getPos(), new CoffeeGL.Vec3(eq.x,@string_height,eq.y) 


    @white_start.matrix.setPos current_state.start_interp.set dt
    @white_end.matrix.setPos current_state.end_interp.set dt
  
    @physics.postMessage {cmd : "white_start_move", data: @white_start.matrix.getPos() }
    @physics.postMessage {cmd : "white_end_move", data: @white_end.matrix.getPos() }
  
  _stateMoveEpicycle : (dt) =>

    current_state = @stack[@stack_idx]

    if not current_state.pos_interp?

      d = @system.state.deferentPosition
      c = @system.state.basePosition
      v = @system.state.parallelPosition
      dr = @system.state.deferentAngle
      e = @system.state.epicyclePrePosition
      

      current_state.pos_interp = new CoffeeGL.Interpolation @epicycle.matrix.getPos(), new CoffeeGL.Vec3 e.x,0,e.y

    @epicycle.matrix.identity()
    @epicycle.matrix.translate current_state.pos_interp.set dt
    #@epicycle.matrix.rotate new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad 90 #sCoffeeGL.degToRad(90-dr)
    
   
        
  _stateRotateEpicycle : (dt) =>

     # Now rotate the epicycle around the deferent till it reaches the white line      
    #tmatrix = new CoffeeGL.Matrix4()
      
    #tmatrix.translate new CoffeeGL.Vec3 d.x, 0, d.y
    #tmatrix.rotate new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad(mr)
      
    #tmatrix.mult @epicycle.matrix
    #@epicycle.matrix.copyFrom(tmatrix)

  _stateRotateLabel : (dt) =>
    pangle = @system.state.pointerAngle
    @pointer.matrix.identity()
    @pointer.matrix.rotate new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad(pangle)

    cp = @system.state.pointerPoint

    @marker.matrix.identity()
    @marker.matrix.translate(new CoffeeGL.Vec3(cp.x,0.6,cp.y))


  _stateMoveBlackStringFinal : (dt) =>


  addStates : (planet, date) ->
    if planet in ['mars','venus','jupiter','saturn']
      @stack = []
      @stack.push new EquatorieState "Select Date and Planet", () => do (planet,date) => @_stateSetPlanetDate(planet,date)
      @stack.push new EquatorieState "Calculate Mean Motus", @_stateCalculateMeanMotus
      @stack.push new EquatorieState "Move Black Thread", @_stateMoveBlackThread
      @stack.push new EquatorieState "Move White Thread", @_stateMoveWhiteThread
      @stack.push new EquatorieState "Move Epicycle", @_stateMoveEpicycle
      @stack.push new EquatorieState "Rotate Label", @_stateRotateLabel

  # reset all the things

  reset : () ->
    # Clear the stack
    @stack = []
    @stack_idx = 0



  # Called when the button is pressed in dat.gui. Solve for the chosen planet
  solveForPlanet : (planet, date) ->

    # Clear the stack
    @stack = []
    @stack_idx = 0

    @addStates(planet,date)

    for state in @stack
      state.update(1.0)

  onMouseDown : (event) ->
    console.log event
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
    
    planets = ["mars","venus","jupiter","saturn"]
    @chosen_planet = "mars"

    controller = @datgui.add(@,'chosen_planet',planets)
    controller = @datgui.add(@,'solveForCurrentDatePlanet')
    controller = @datgui.add(@,'advance_date',0,730)
    controller.onChange( (value) => 
      @solveForCurrentDatePlanet()
    )

    controller = @datgui.add(@, "stepForward")

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

    if @stack.length == 0
      @addStates(@chosen_planet, new Date() )
      @stack_idx = 0
    else
      if @stack_idx + 1 < @stack.length
        # Make sure current state has completed
        @stack[@stack_idx].update(1.0)
        @time.dt = 0
        @stack_idx +=1
        

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