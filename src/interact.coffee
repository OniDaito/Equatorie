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

    @_initGUI()

  update : (dt) ->


   # Called when the button is pressed in dat.gui. Solve for the chosen planet
  solveForPlanet : (planet, date) ->

    #date = new Date("May 31, 1585 00:00:00")

    console.log @system.calculateDeferentAngle planet, date

    [ma, mv] = @system.calculateMeanMotus planet, date

    console.log "Mean Motus: " + ma
    console.log "Days Passed: " + @system.calculateDate date

    mv.normalize()
    mv.multScalar(10.0)

    # Black to Centre and mean motus
    @black_start.matrix.identity()
    @black_start.matrix.translate(new CoffeeGL.Vec3(0,@string_height,0))

    @black_end.matrix.identity()
    @black_end.matrix.translate(new CoffeeGL.Vec3(mv.x, @string_height, mv.y) )

    @physics.postMessage {cmd : "black_start_move", data: @black_start.matrix.getPos() }
    @physics.postMessage {cmd : "black_end_move", data: @black_end.matrix.getPos() }

    # White string to the Equant and parallel to black
    eq = @system.calculateEquantPosition planet, date
    pv = @system.calculateParallel planet, date
    pv.sub(eq)
    pv.normalize()
    pv.multScalar(10.0)
    pv.add(eq)

  
    @white_start.matrix.identity()
    @white_start.matrix.translate(new CoffeeGL.Vec3(eq.x,@string_height,eq.y))

    @white_end.matrix.identity()
    @white_end.matrix.translate(new CoffeeGL.Vec3(pv.x, @string_height, pv.y ))
  
    @physics.postMessage {cmd : "white_start_move", data: @white_start.matrix.getPos() }
    @physics.postMessage {cmd : "white_end_move", data: @white_end.matrix.getPos() }
  
    # Epicycle to position
  
    if @epicycle?

      [d, c, v, dr, mr] = @system.calculateEpicyclePosition(planet, date)
      @epicycle.matrix.identity()
    
      @epicycle.matrix.translate new CoffeeGL.Vec3 c.x,0,c.y  
      @epicycle.matrix.rotate new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad(90-dr)
    
      # Now rotate the epicycle around the deferent till it reaches the white line
      
      tmatrix = new CoffeeGL.Matrix4()
      
      tmatrix.translate new CoffeeGL.Vec3 d.x, 0, d.y
      tmatrix.rotate new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad(mr)
      
      tmatrix.mult @epicycle.matrix
      @epicycle.matrix.copyFrom(tmatrix)
      
    # Pointer angle
    pangle = @system.calculatePointerAngle(planet, date)
    @pointer.matrix.identity()
    @pointer.matrix.rotate new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad(pangle)

    cp = @system.calculatePointerPoint planet, date

    @marker.matrix.identity()
    @marker.matrix.translate(new CoffeeGL.Vec3(cp.x,0.6,cp.y))

    @system.calculateTruePlace planet, date


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

    # Shader Controls
    controller = @datgui.add(@pointer,'uAlphaX',0,1)
    controller = @datgui.add(@pointer,'uAlphaY',0,1)

    controller = @datgui.add(@epicycle,'uAlphaX',0,1)
    controller = @datgui.add(@epicycle,'uAlphaY',0,1)

  solveForCurrentDatePlanet : () ->
    date = new Date()
    date.setDate date.getDate() + @advance_date 
    @solveForPlanet(@chosen_planet, date)
    
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