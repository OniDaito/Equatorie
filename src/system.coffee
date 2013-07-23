
class EquatorieSystem

  constructor : () ->

    @base_radius = 6.0        # used with epicycle ratio - Blender Units
    @epicycle_radius = 6.353  # used with epicycle ratio - Blender Units
    @epicycle_thickness = @epicycle_radius - @base_radius
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
      apogee_longitude : 148.6166667
      mean_longitude : 266.25
      mean_anomaly : 13.45


    # Epoch from Evans

    @epoch = new Date ("January 1, 1900 00:00:00")

    @epoch_julian = 2415020
   
    # consistent pieces of information at each step
    @mean_motus_angle = 0


  calculateDeferentAngle : (planet, date) ->
    
    angle = -@planet_data[planet].apogee_longitude - ( @precession * @calculateDate date )
    angle

  calculateDeferentPosition : (planet, date) ->

    x = @base_radius * @planet_data[planet].deferent_eccentricity * Math.cos(CoffeeGL.degToRad (@calculateDeferentAngle planet, date))
    y = @base_radius * @planet_data[planet].deferent_eccentricity * Math.sin(CoffeeGL.degToRad (@calculateDeferentAngle planet, date))
    [x,y]

  calculateEquantPosition : (planet, date) ->
    [x,y] = @calculateDeferentPosition planet, date
    new CoffeeGL.Vec2(x*2, y*2)


 
  calculateDate : (date) ->
    # Worked out from the date (current) and the tables above
    # 1900, January 1st 00:00 evening (so midnight on the Dec 31)
    # return the number of days - use Julian dates

    a = (14 - (date.getMonth()+1)) / 12
    y = date.getFullYear() + 4800 - a
    m = (date.getMonth()+1) + (12 * a )-3
    j = date.getDate() + (153 * m  + 2)/ 5 + (365 * y) + (y/4) - (y/100) + (y/400) - 32045

    #Math.abs(date - @epoch) / 86400000
    j - @epoch_julian

  # Return the mean motus angle plus the postion on the rim of the base
  calculateMeanMotus : (planet, date) ->
    
    passed = @calculateDate date
    mean_motus_angle = (@planet_data[planet].mean_longitude + (@planet_data[planet].deferent_speed * passed) ) % 360 * -1
    
    [mean_motus_angle, new CoffeeGL.Vec2(@base_radius * Math.cos( CoffeeGL.degToRad(mean_motus_angle) ), 
      @base_radius * Math.sin( CoffeeGL.degToRad(mean_motus_angle) ))]

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
  calculateParallel : (planet, date) ->

    passed = @calculateDate date
    dangle = @calculateDeferentAngle planet, date
    
    cr = Math.cos CoffeeGL.degToRad dangle
    sr = Math.sin CoffeeGL.degToRad dangle

    base_position = new CoffeeGL.Vec2(@base_radius * cr, @base_radius * sr)

    deferent_position = new CoffeeGL.Vec2(base_position.x * @planet_data[planet].deferent_eccentricity,
      base_position.y * @planet_data[planet].deferent_eccentricity)

    equant_position = @calculateEquantPosition(planet, date)

    [motus_angle, motus_position] = @calculateMeanMotus(planet,date)
    dir = motus_position.copy()
    dir.normalize()

    @rayCircleIntersection(equant_position, dir, deferent_position, @base_radius)
    

  calculateEpicyclePosition : (planet, date) ->
    # Rotate the epicycle so its 0 point is on the deferent, then rotate around the deferent
    # by the mean motus - two steps

    passed = @calculateDate date
    dangle = @calculateDeferentAngle planet, date
    
    cr = Math.cos CoffeeGL.degToRad dangle
    sr = Math.sin CoffeeGL.degToRad dangle

    base_position = new CoffeeGL.Vec2(@base_radius * cr, @base_radius * sr)
    
    deferent_position = new CoffeeGL.Vec2(base_position.x * @planet_data[planet].deferent_eccentricity,
      base_position.y * @planet_data[planet].deferent_eccentricity)
 
    equant_position = @calculateEquantPosition(planet, date)
   
    # At this point we have the first transform, before we need to rotate the epicycle over
    # the white string
    fangle = 0

    # Line equation - p = s + tD
    v = @calculateParallel planet,date
  
    if v.x != 0 and v.y != 0

      f0 = CoffeeGL.radToDeg Math.atan2 base_position.y - deferent_position.y, base_position.x - deferent_position.x
      f1 = CoffeeGL.radToDeg Math.atan2 v.y - deferent_position.y, v.x - deferent_position.x
      fangle = f0 - f1

    [deferent_position, base_position, v, dangle, fangle ]

  # Turned anti-clockwise around the epicycle
  # We count this as the angle from the white string, not the zero point
  calculatePointerAngle : (planet, date) ->
    passed = @calculateDate(date)
    angle = @planet_data[planet].mean_anomaly + (@planet_data[planet].epicycle_speed * passed)
      
    console.log "Label Angle Real: " + @planet_data[planet].mean_anomaly + "," + @planet_data[planet].epicycle_speed + "," + angle

    [ma, mm] = @calculateMeanMotus(planet,date)

    [deferent_position, base_position, v, dangle, fangle ] = @calculateEpicyclePosition(planet, date)
   
    ca = Math.cos(CoffeeGL.degToRad(-fangle))
    sa = Math.sin(CoffeeGL.degToRad(-fangle))

    epipos = new CoffeeGL.Vec2(base_position.x * ca - base_position.y * sa, 
        base_position.x * sa + base_position.y * ca)
    epipos.add deferent_position

    pt0 = CoffeeGL.Vec2.sub(mm, deferent_position )
    pt1 = CoffeeGL.Vec2.sub(epipos, deferent_position)

    aa = CoffeeGL.radToDeg( Math.acos( CoffeeGL.Vec2.dot( CoffeeGL.Vec2.normalize( pt0), 
      CoffeeGL.Vec2.normalize(pt1))))

    dv = CoffeeGL.Vec3.cross(new CoffeeGL.Vec3(0,1,0), new CoffeeGL.Vec3(pt0.x,0,pt0.y) )

    if dv.x > 0
      aa *= -1

    

    90 - (aa/2) + angle
  

  # in Global co-ordinates
  calculatePointerPoint : (planet,date) ->
    angle = @calculatePointerAngle planet,date
    deferent_position = @calculateDeferentPosition(planet, date)

    [motus_angle, motus_position] = @calculateMeanMotus(planet,date)
    equant_position = @calculateEquantPosition(planet, date)
    dir = motus_position.copy()
    dir.normalize()

    [deferent_position, base_position, v, dangle, fangle ] = @calculateEpicyclePosition(planet, date)
    ca = Math.cos(CoffeeGL.degToRad(-fangle))
    sa = Math.sin(CoffeeGL.degToRad(-fangle))

    epipos = new CoffeeGL.Vec2(base_position.x * ca - base_position.y * sa, 
        base_position.x * sa + base_position.y * ca)
    epipos.add deferent_position

    # At this point perp is the point underneath the epicycle
    dir = CoffeeGL.Vec2.normalize(CoffeeGL.Vec2.sub(epipos,deferent_position))
    
    # Move left down the limb
    perp = dir.copy()
    perp.x = -dir.y
    perp.y = dir.x

    perp.multScalar (@base_radius * @planet_data[planet].epicycle_ratio )

    ca = Math.cos (CoffeeGL.degToRad(-angle))
    sa = Math.sin (CoffeeGL.degToRad(-angle))

    perp = new CoffeeGL.Vec2(perp.x * ca - perp.y * sa, perp.x * sa + perp.y * ca)

    perp.add epipos

  # in degrees from the centre of the base and the sign of aries (x axis in this system)
  calculateTruePlace : (planet, date) ->
    pp = @calculatePointerPoint planet,date
    dir = CoffeeGL.Vec2.normalize pp
    xaxis = new CoffeeGL.Vec2(1,0)
    angle = CoffeeGL.radToDeg Math.acos xaxis.dot dir
    console.log "True Place: " + angle

module.exports = 
  EquatorieSystem : EquatorieSystem