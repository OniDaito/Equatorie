##>VERTEX
{{ShaderLibrary.Basic}}
{{ShaderLibrary.VertexTexCoord}}

varying vec4 vTransformedNormal;

void main(void) {
  gl_Position = uModelMatrix * vec4(aVertexPosition, 1.0);
  vTexCoord = aVertexTexCoord;

}

##>FRAGMENT
precision mediump float;

{{ShaderLibrary.Basic}}
{{ShaderLibrary.VertexTexCoord}}

void main() {

  vec2 d = vec2(vTexCoord.x - 0.5, vTexCoord.y - 0.5);
  float a = length(d);
  float l = 1.0 - a * 2.0;

  gl_FragColor = vec4(l,l,l,1.0);
}