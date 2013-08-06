
class EquatorieSystem

  constructor : () ->

    @base_radius = 6.0        # used with epicycle ratio - Blender Units
    @epicycle_radius = 6.0  # used with epicycle ratio - Blender Units
    @epicycle_thickness = 0.333334
    @precession = 0.00003838  # Degrees per day

    @planet_data = {}

    # Data for the Equatorie mathematical model
    # Taken from the Evans book
    # Speed is in degrees per day (modified to be decimal)

    @planet_data.venus =
      deferent_speed : 0.98564734
      epicycle_speed : 0.61652156
      epicycle_ratio : 0.72294
      deferent_eccentricity : 0.0145
      apogee_longitude : 98.1666667
      mean_longitude : 279.7
      mean_anomaly : 63.383

    @planet_data.mars =
      deferent_speed : 0.52407116
      epicycle_speed : 0.46157618
      epicycle_ratio : 0.6563
      deferent_eccentricity : 0.10284
      apogee_longitude : 148.6166667
      mean_longitude : 293.55
      mean_anomaly : 346.15

    @planet_data.jupiter =
      deferent_speed : 0.08312944
      epicycle_speed : 0.90251790
      epicycle_ratio : 0.1922
      deferent_eccentricity : 0.04817
      apogee_longitude : 188.9666667
      mean_longitude : 238.16666667
      mean_anomaly : 41.5333333

     @planet_data.saturn =
      deferent_speed : 0.03349795
      epicycle_speed : 0.95214939
      epicycle_ratio : 0.10483
      deferent_eccentricity : 0.05318
      apogee_longitude : 270.76666667
      mean_longitude : 266.25
      mean_anomaly : 13.45

    # Epoch from Evans

    @epoch = new Date ("January 1, 1900 00:00:00")
    @epoch_julian = 2415020
   
    # consistent pieces of information at each step
    # The system records its state as we progress through
    # This means things must be done in order.

    # Set Planet and Calculate Date must be called first.

    @reset()

  # This function sets the state above and is the only function to be called externally 
  # along with reset
  
  solveForPlanetDate : (planet, date) ->
    @_setPlanet(planet)   
    @_calculateDate(date)
    @_calculateDeferentAngle()
    @_calculateDeferentPosition()
    @_calculateEquantPosition()
    @_calculateMeanMotus()
    @_calculateParallel()
    @_calculateEpicyclePosition()
    @_calculatePointerAngle()
    @_calculatePointerPoint()
    @_calculateTruePlace()

  reset : () ->
    @state = 
      meanMotus : 0
      meanMotusPosition : 0
      deferentAngle : 0
      deferentPosition : 0
      passed : 0
      planet : ''
      date : 0
      parallelPosition : 0
      pointerAngle : 0
      equantPosition : 0
      epicycleRotation: 0
      epicyclePosition : 0
      basePosition : 0
      truePlace : 0

  _setPlanet : (planet) ->
    @state.planet = planet
    @

  _calculateDate : (date) ->
    # Worked out from the date (current) and the tables above
    # 1900, January 1st 00:00 evening (so midnight on the Dec 31)
    # return the number of days - use Julian dates

    a = (14 - (date.getMonth()+1)) / 12
    y = date.getFullYear() + 4800 - a
    m = (date.getMonth()+1) + (12 * a )-3
    j = date.getDate() + (153 * m  + 2)/ 5 + (365 * y) + (y/4) - (y/100) + (y/400) - 32045

    #Math.abs(date - @epoch) / 86400000
    p = j - @epoch_julian

    @state.passed = p
    p

  
  _calculateDeferentAngle : () ->
    if @state.planet in ['mars','venus','jupiter','saturn']
      angle = -@planet_data[@state.planet].apogee_longitude - ( @precession * @state.date )
      @state.deferentAngle = angle
      return angle
    @

  _calculateDeferentPosition : () ->
    if @state.planet in ['mars','venus','jupiter','saturn']
      x = @base_radius * @planet_data[@state.planet].deferent_eccentricity * Math.cos(CoffeeGL.degToRad @state.deferentAngle)
      y = @base_radius * @planet_data[@state.planet].deferent_eccentricity * Math.sin(CoffeeGL.degToRad @state.deferentAngle)
      @state.deferentPosition = new CoffeeGL.Vec2 x,y
      return @state.deferentPosition
    @

  _calculateEquantPosition : () ->
    if @state.planet in ['mars','venus','jupiter','saturn']
      @state.equantPosition = new CoffeeGL.Vec2 @state.deferentPosition.x*2, @state.deferentPosition.y*2
      return @state.equantPosition
 
  
  # Return the mean motus angle plus the postion on the rim of the base
  _calculateMeanMotus : () ->
    
    passed = @state.passed
    mean_motus_angle = (@planet_data[@state.planet].mean_longitude + (@planet_data[@state.planet].deferent_speed * passed) ) % 360 * -1
    @state.meanMotus = mean_motus_angle

    mean_motus_position = new CoffeeGL.Vec2(@base_radius * Math.cos( CoffeeGL.degToRad(mean_motus_angle) ), 
      @base_radius * Math.sin( CoffeeGL.degToRad(mean_motus_angle) ))

    @state.meanMotusPosition = mean_motus_position

    [mean_motus_angle, mean_motus_position]

  # http://stackoverflow.com/questions/1073336/circle-line-collision-detection
  # Given a ray and circle, solve the quadratic and find intersection points
  rayCircleIntersection : (ray_start, ray_dir, circle_centre, circle_radius) ->

    f = CoffeeGL.Vec2.sub(ray_start,circle_centre)
    r = circle_radius

    a = ray_dir.dot( ray_dir )
    b = 2*f.dot( ray_dir )
    c = f.dot( f ) - r*r

    v = new CoffeeGL.Vec2()

    discriminant = b*b-4*a*c

    if discriminant != 0
      discriminant = Math.sqrt(discriminant)
      t1 = (-b - discriminant)/(2*a)
      t2 = (-b + discriminant)/(2*a)

      t = t2
      t = t1 if t2 < 0 

      # Plug back into our line equation
      
      v.copyFrom(ray_start)
      d2 = CoffeeGL.Vec2.multScalar(ray_dir,t)
      v.add(d2)

    v

  # Find where the parallel line from the Equant, parallel with the meanmotus, cuts the rim
  _calculateParallel : () ->

    passed = @state.passed
    dangle = @state.deferentAngle
    
    cr = Math.cos CoffeeGL.degToRad dangle
    sr = Math.sin CoffeeGL.degToRad dangle

    base_position = new CoffeeGL.Vec2(@base_radius * cr, @base_radius * sr)
    @state.basePosition = base_position

    deferent_position = @state.deferentPosition
    equant_position = @state.equantPosition

    dir = @state.meanMotusPosition.copy()
    dir.normalize()

    @state.parallelPosition = @rayCircleIntersection(equant_position, dir, deferent_position, @base_radius)
    @state.parallelPosition

  _calculateEpicyclePosition : () ->
    # Rotate the epicycle so its 0 point is on the deferent, then rotate around the deferent
    # by the mean motus - two steps

    passed = @state.passed
    dangle = @state.deferentAngle
    
    cr = Math.cos CoffeeGL.degToRad dangle
    sr = Math.sin CoffeeGL.degToRad dangle

    @state.basePosition = new CoffeeGL.Vec2(@base_radius * cr, @base_radius * sr)
    deferent_position = @state.deferentPosition
    equant_position = @state.equantPosition
   
    # At this point we have the first transform, before we need to rotate the epicycle over
    # the white string
    fangle = 0

    # Line equation - p = s + tD
    v = @state.parallelPosition
  
    if v.x != 0 and v.y != 0

      f0 = CoffeeGL.radToDeg Math.atan2 @state.basePosition.y - deferent_position.y, @state.basePosition.x - deferent_position.x
      f1 = CoffeeGL.radToDeg Math.atan2 v.y - deferent_position.y, v.x - deferent_position.x
      fangle = f0 - f1

    @state.epicycleRotation = fangle

    [deferent_position, @state.basePosition, v, dangle, fangle ]

  # Turned anti-clockwise around the epicycle
  # We count this as the angle from the white string, not the zero point
  _calculatePointerAngle : () ->
    passed = @state.passed
    angle = @planet_data[@state.planet].mean_anomaly + (@planet_data[@state.planet].epicycle_speed * passed)
      
    ca = Math.cos(CoffeeGL.degToRad(-@state.epicycleRotation))
    sa = Math.sin(CoffeeGL.degToRad(-@state.epicycleRotation))

    epipos = new CoffeeGL.Vec2(@state.basePosition.x * ca - @state.basePosition.y * sa, 
        @state.basePosition.x * sa + @state.basePosition.y * ca)
    epipos.add @state.deferentPosition

    @state.epicyclePosition = epipos

    pt0 = CoffeeGL.Vec2.sub(@state.meanMotusPosition, @state.deferentPosition)
    pt1 = CoffeeGL.Vec2.sub(epipos, @state.deferentPosition)

    aa = CoffeeGL.radToDeg( Math.acos( CoffeeGL.Vec2.dot( CoffeeGL.Vec2.normalize( pt0), 
      CoffeeGL.Vec2.normalize(pt1))))

    dv = CoffeeGL.Vec3.cross(new CoffeeGL.Vec3(0,1,0), new CoffeeGL.Vec3(pt0.x,0,pt0.y) )

    if dv.x > 0
      aa *= -1


    pa = 90 - (aa/2) + angle
    @state.pointerAngle = pa
    pa
  

  # in Global co-ordinates
  _calculatePointerPoint : () ->
    angle = @state.pointerAngle
    deferent_position = @state.deferentPosition

    motus_angle = @state.meanMotus
    motus_position = @state.meanMotusPosition

    equant_position = @state.equantPosition
    dir = motus_position.copy()
    dir.normalize()

    fangle = @state.epicycleRotation
    ca = Math.cos(CoffeeGL.degToRad(-fangle))
    sa = Math.sin(CoffeeGL.degToRad(-fangle))

    epipos = @state.epicyclePosition 

    # At this point perp is the point underneath the epicycle
    dir = CoffeeGL.Vec2.normalize(CoffeeGL.Vec2.sub(epipos,deferent_position))
    
    # Move left down the limb
    perp = dir.copy()
    perp.x = -dir.y
    perp.y = dir.x

    perp.multScalar (@base_radius * @planet_data[@state.planet].epicycle_ratio )

    ca = Math.cos (CoffeeGL.degToRad(-angle))
    sa = Math.sin (CoffeeGL.degToRad(-angle))

    perp = new CoffeeGL.Vec2(perp.x * ca - perp.y * sa, perp.x * sa + perp.y * ca)

    perp.add epipos

    @state.pointerPoint = perp
    perp 

  # in degrees from the centre of the base and the sign of aries (x axis in this system)
  _calculateTruePlace : () ->
    pp = @state.pointerPoint
    dir = CoffeeGL.Vec2.normalize pp
    xaxis = new CoffeeGL.Vec2(1,0)
    angle = CoffeeGL.radToDeg Math.acos xaxis.dot dir
    @state.truePlace = angle
    angle

module.exports = 
  EquatorieSystem : EquatorieSystem