##>VERTEX
{{ShaderLibrary.Basic}}
{{ShaderLibrary.BasicCamera}}
{{ShaderLibrary.BasicVertexColours}}

varying vec4 vTransformedNormal;

void main(void) {
  gl_Position = uProjectionMatrix * uCameraMatrix * uModelMatrix * vec4(aVertexPosition, 1.0);

  vColor = aVertexColour;
}

##>FRAGMENT
precision mediump float;

{{ShaderLibrary.Basic}}
{{ShaderLibrary.BasicVertexColours}}

void main() { 
  gl_FragColor = vColor; 
}