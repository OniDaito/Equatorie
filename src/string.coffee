
# Given some bullet physics represent the string

class EquatorieString extends CoffeeGL.Node
  constructor : (length, thickness, segments) ->
    super()
    seglength = length / segments

    segment_geom = new CoffeeGL.Shapes.Cylinder(thickness, 12, seglength)

    for i in [0..segments-1]
    
      segment_node = new CoffeeGL.Node(segment_geom)
      @add segment_node


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