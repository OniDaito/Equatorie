class EquatorieSystem

  constructor : () ->

    @base_size = 6.0 # used with epicycle ratio


    @planet_data = {}

    # Data for the Equatorie mathematical model

    # Taken from the Evans book

    # Speed is in degrees per day (modified to be decimal)
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

    @mean_motus = 0     # Arc of motion of epicycle around deferent
    @mean_argument = 0  # Arc of motion of planet around epicycle


  calculateDeferentPosition : (planet) ->
    x = @base_size * @planet_data[planet].deferent_eccentricity * Math.cos(CoffeeGL.degToRad @planet_data[planet].apogee_longitude)
    y = @base_size * @planet_data[planet].deferent_eccentricity * Math.sin(CoffeeGL.degToRad @planet_data[planet].apogee_longitude)
    [x,y]

   calculateEquantPosition : (planet) ->
    [x,y] = @calculateDeferentPosition planet
    [x * 2, y * 2]

  calculateEpicyclePosition : (planet) ->
    # relative to 0 degrees - the sign of aries    
    # Centre of the deferent circle
 
    # now rotate by mean motus and radius of epicycle (6.353 at present)
    [x,y] = @calculateDeferentPosition planet
   

    rx = @base_size * Math.sin( CoffeeGL.degToRad @mean_motus)
    ry = @base_size * Math.cos( CoffeeGL.degToRad @mean_motus)

    [x + rx, y + ry]  

module.exports = 
  EquatorieSystem : EquatorieSystem