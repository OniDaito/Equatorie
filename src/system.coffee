class EquatorieSystem

  constructor : () ->

    @base_radius = 6.0 # used with epicycle ratio
    @epicycle_radius = 6.353 # used with epicycle ratio
    @epicycle_thickness = @epicycle_radius - @base_radius

    @planet_data = {}

    # Data for the Equatorie mathematical model
    # Taken from the Evans book
    # Speed is in degrees per day (modified to be decimal)
    #


    @planet_data.venus =
      deferent_speed : 0.985
      epicycle_speed : 0.616
      epicycle_ratio : 0.72294
      deferent_eccentricity : 0.0145
      apogee_longitude : 98.1666667
      mean_longitude : 279.7
      mean_anomaly : 63.383

    @planet_data.mars =
      deferent_speed : 0.524
      epicycle_speed : 0.461
      epicycle_ratio : 0.6563
      deferent_eccentricity : 0.10284
      apogee_longitude : 148.6166667
      mean_longitude : 293.55
      mean_anomaly : 346.15

    @planet_data.jupiter =
      deferent_speed : 0.083
      epicycle_speed : 0.902
      epicycle_ratio : 0.1922
      deferent_eccentricity : 0.04817
      apogee_longitude : 188.9666667
      mean_longitude : 238.16666667
      mean_anomaly : 41.5333333

     @planet_data.saturn =
      deferent_speed : 0.033
      epicycle_speed : 0.952
      epicycle_ratio : 0.10483
      deferent_eccentricity : 0.05318
      apogee_longitude : 148.6166667
      mean_longitude : 266.25
      mean_anomaly : 13.45

   


  calculateDeferentAngle : (planet) ->
    # TODO - Apogee Longitude needs some adjustment given the current date
    @planet_data[planet].apogee_longitude


  calculateDeferentPosition : (planet) ->

    x = @base_radius * @planet_data[planet].deferent_eccentricity * Math.cos(CoffeeGL.degToRad (@calculateDeferentAngle planet))
    y = @base_radius * @planet_data[planet].deferent_eccentricity * Math.sin(CoffeeGL.degToRad (@calculateDeferentAngle planet))
    [x,y]

  calculateEquantPosition : (planet) ->
    [x,y] = @calculateDeferentPosition planet
    new CoffeeGL.Vec2(x*2,y*2)


 
  calculateDate : (planet, date) ->
    # Worked out from the date (current) and the tables above
    # 1900, January 1st 00:00 evening (so midnight on the Dec 31)
    
    epoch = new Date ("January 1, 1900 00:00:00")
    passed = Math.abs(date - epoch) / 86400000
    passed


  calculateMeanMotus : (planet, date) ->
    
    passed = @calculateDate(planet, date)
    angle = @planet_data[planet].mean_longitude + @planet_data[planet].deferent_speed * passed % 360
    
    new CoffeeGL.Vec2(@base_radius * Math.cos( CoffeeGL.degToRad(angle) ), 
      @base_radius * Math.sin( CoffeeGL.degToRad(angle) ))

  # Find where the parallel line from the Equant, parallel with the meanmotus, cuts the rim
  calculateParallel : (planet, date) ->

    passed = @calculateDate(planet, date)
    dangle = @calculateDeferentAngle (planet)
    
    cr = Math.cos CoffeeGL.degToRad dangle
    sr = Math.sin CoffeeGL.degToRad dangle

    base_position = new CoffeeGL.Vec2(@base_radius * cr, @base_radius * sr)

    deferent_position = new CoffeeGL.Vec2(base_position.x * @planet_data[planet].deferent_eccentricity,
      base_position.y * @planet_data[planet].deferent_eccentricity)

    equant_position = @calculateEquantPosition(planet)

    motus_position = @calculateMeanMotus(planet,date)
    dir = motus_position.copy()
    dir.normalize()

    f = CoffeeGL.Vec2.sub(deferent_position, equant_position)

    r = @base_radius

    a = dir.dot( dir )
    b = 2*f.dot( dir )
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
      
      v.copyFrom(equant_position)
      d2 = CoffeeGL.Vec2.multScalar(dir,t)
      v.add(d2)

    v

  calculateEpicyclePosition : (planet, date) ->
    # Rotate the epicycle so its 0 point is on the deferent, then rotate around the deferent
    # by the mean motus - two steps

    passed = @calculateDate(planet, date)
    mangle = (@planet_data[planet].mean_longitude + @planet_data[planet].deferent_speed * passed) % 360
    dangle = @calculateDeferentAngle (planet)
    
    cr = Math.cos CoffeeGL.degToRad dangle
    sr = Math.sin CoffeeGL.degToRad dangle

    base_position = new CoffeeGL.Vec2(@base_radius * cr, @base_radius * sr)
    
    deferent_position = new CoffeeGL.Vec2(base_position.x * @planet_data[planet].deferent_eccentricity,
      base_position.y * @planet_data[planet].deferent_eccentricity)

    
    equant_position = @calculateEquantPosition(planet)
   
  
    # At this point we have the first transform, before we need to rotate the epicycle over
    # the white string

    fangle = 0

    # Line equation - p = s + tD
    v = @calculateParallel planet,date
    if v.x != 0 and v.y != 0

      f0 = CoffeeGL.radToDeg Math.atan2 base_position.y - deferent_position.y, base_position.x - deferent_position.x
      f1 = CoffeeGL.radToDeg Math.atan2 v.y - deferent_position.y, v.x - deferent_position.x
      fangle = f0 - f1

      console.log(f0,f1)

    [deferent_position, base_position, v, dangle, fangle ]



module.exports = 
  EquatorieSystem : EquatorieSystem