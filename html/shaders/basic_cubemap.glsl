##>VERTEX
{{ShaderLibrary.Basic}}
{{ShaderLibrary.BasicVertexColours}}
{{ShaderLibrary.BasicVertexNormals}}

void main(void) {
    gl_Position = uProjectionMatrix * uCameraMatrix * uModelViewMatrix * vec4(aVertexPosition, 1.0);
    vNormal = aVertexNormal;
    vColor = aVertexColour;
}
    
##>FRAGMENT
{{ShaderLibrary.Basic}}
{{ShaderLibrary.BasicVertexColours}}
{{ShaderLibrary.BasicVertexNormals}}

uniform samplerCube uSampler;
void main(void) {
    gl_FragColor = textureCube(uSampler,vNormal);
}
