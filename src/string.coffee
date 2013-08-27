
# Given some bullet physics represent the string

class EquatorieString extends CoffeeGL.Node
  constructor : (length, thickness, segments) ->
    super()
    seglength = length / segments

    #segment_geom = new CoffeeGL.Shapes.Cylinder(thickness, 12, seglength)

    #for i in [0..segments-1]
    
    #  segment_node = new CoffeeGL.Node(segment_geom)
    #  @add segment_node

    @add @_makeSegments thickness,12,seglength,segments

  _makeSegments : (radius, resolution, height, segments) ->

    geom = new CoffeeGL.Geometry()

    geom.indices = []

    height = height / 2.0

    # top
    geom.v.push new CoffeeGL.Vertex new CoffeeGL.Vec3(0,height,0), new CoffeeGL.Colour.RGBA.WHITE(), new CoffeeGL.Vec3(0,0,1.0), new CoffeeGL.Vec2(0.5,1.0)
    for i in [1..resolution]

      x = radius * Math.sin(CoffeeGL.degToRad(360.0 / resolution * i))
      z = radius * Math.cos(CoffeeGL.degToRad(360.0 / resolution * i))
      
      tangent = new CoffeeGL.Vec3(x,0,z)
      tangent.normalize()
      tangent.cross new CoffeeGL.Vec3(0,1,0)

      geom.v.push new CoffeeGL.Vertex new CoffeeGL.Vec3(x,height,z), new CoffeeGL.Colour.RGBA.WHITE(), CoffeeGL.Vec3.normalize(new CoffeeGL.Vec3(x,1.0,z)), new CoffeeGL.Vec2(i/resolution,0.0), tangent
    

    # top cap
    for i in [1..resolution]
      geom.indices.push 0
      geom.indices.push i
      if i == resolution
        geom.indices.push 1
      else
        geom.indices.push (i+1)

    
    for i in [1..segments]

      # next end
      for j in [1..resolution]

        x = radius * Math.sin(CoffeeGL.degToRad(360.0 / resolution * j))
        z = radius * Math.cos(CoffeeGL.degToRad(360.0 / resolution * j))

        tangent = new CoffeeGL.Vec3(x,0,z)
        tangent.normalize()
        tangent.cross new CoffeeGL.Vec3(0,-1,0)
        
        geom.v.push new CoffeeGL.Vertex new CoffeeGL.Vec3(x,-height * i ,z), new CoffeeGL.Colour.RGBA.WHITE(), CoffeeGL.Vec3.normalize(new CoffeeGL.Vec3(x,-1.0,z)), new CoffeeGL.Vec2(j/resolution, i/segments ), tangent

      #sides1

      s = (i - 1) * resolution + 1
      e = s + resolution
  
      for j in [0..resolution-1]
        geom.indices.push (s + j)
        geom.indices.push (e + j)
        if j == (resolution-1)
          geom.indices.push (e)
        else
          geom.indices.push (e + j + 1)

      
      for j in [0..resolution-1]
        geom.indices.push (s+j)
        if j == (resolution-1)
          geom.indices.push (e)
          geom.indices.push (s)
        else
          geom.indices.push (e+j+1)
          geom.indices.push (s+j+1)
      

    
    # Very last point for bottom cap
    geom.v.push new CoffeeGL.Vertex new CoffeeGL.Vec3(0,-height * segments,0), new CoffeeGL.Colour.RGBA.WHITE(), new CoffeeGL.Vec3(0,0,-1.0), new CoffeeGL.Vec2(0.5,1.0)

     # bottom cap
    s = (segments * resolution) + 2
    e = s + resolution - 1
    for i in [s..e]
      geom.indices.push (s - 1)
      if i == e
        geom.indices.push s
      else
        geom.indices.push (i+1)

      geom.indices.push i


    for i in [0..geom.indices.length-1] by 3
      geom.faces.push new CoffeeGL.Triangle(geom.v[geom.indices[i]], geom.v[geom.indices[i+1]], geom.v[geom.indices[i+2]])




    #geom.layout = "POINTS"
    geom

  update : (data) ->
 
    idx = 0
    for segment in @children

      phys = data.segments[idx]

      segment.matrix.identity()
      tq = new CoffeeGL.Quaternion()
      tv = new CoffeeGL.Vec3 phys.rax, phys.ray, phys.raz
      tq.fromAxisAngle tv,phys.ra
      tmatrix = tq.getMatrix4()
      tmatrix.setPos new CoffeeGL.Vec3 phys.x, phys.y, phys.z

      segment.matrix.copyFrom(tmatrix)
      idx++

module.exports = 
  EquatorieString : EquatorieString