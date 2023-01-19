#ifdef VERTEX_SHADER
#line 2
precision highp float;
uniform mat4 view;
uniform mat4 proj;

uniform float iTime;
float walking = -iTime;

out vec2 vTexCoord;
out vec3 vNormal  ;
flat out int material;

// Work modified in Lab 2
uint sphere(in uint offset,in mat4 mvp,in uint nCols,in uint nRows, int matId){
  uint nCells = nCols * nRows;
  uint verticesPerCell = 6u;
  uint nVertices = nCells * verticesPerCell;
  uint verticesPerRow = nCols * verticesPerCell;

  uint vID = uint(gl_VertexID);
  if(vID < offset || vID >= offset+nVertices)return nVertices;

  material = matId;

  uint cellID = vID / verticesPerCell;
  uint verID  = vID % verticesPerCell;
  
  uint rowID = cellID / nCols;
  uint colID = cellID % nCols;

  uvec2 verOffset[] = uvec2[](
    uvec2(0,0),
    uvec2(1,0),
    uvec2(0,1),
    uvec2(0,1),
    uvec2(1,0),
    uvec2(1,1)
  );

  float zAngleNorm = float(colID + verOffset[verID].x ) / float(nCols);
  float yAngleNorm = float(rowID + verOffset[verID].y ) / float(nRows);


  float yAngle = radians(yAngleNorm * 180.f - 90.f);
  float zAngle = radians(zAngleNorm * 360.f);

  vec2 xyCircle = vec2(         cos(zAngle),sin(zAngle));
  vec3 sphere   = vec3(xyCircle*cos(yAngle),sin(yAngle));

  vTexCoord = vec2(zAngleNorm,yAngleNorm);
  vNormal   = sphere;
  gl_Position = mvp * vec4(sphere,1.f);

  return nVertices;
}

// New geometric figure build
uint box(in uint offset,in mat4 mvp,in uint nCols,in uint nRows, int matId){

  uint nCells = nCols * nRows;
  uint verticesPerCell = 6u;
  uint nVertices = nCells * verticesPerCell;

  uint vID = uint(gl_VertexID);
  if(vID < offset || vID >= offset+nVertices)return nVertices;

  material = matId;
  
  uint indices[] = uint[](
    0u,1u,2u,2u,1u,3u,
    4u,5u,6u,6u,5u,7u,
    0u,4u,2u,2u,4u,6u,
    1u,5u,3u,3u,5u,7u,
    0u,1u,4u,4u,1u,5u,
    2u,3u,6u,6u,3u,7u
  );

  uint nIndices = uint(indices.length());

  vec3 pos;
  for(uint i=0u;i<3u;++i)
    pos[i] = float((indices[vID % nIndices]>>i)&1u); 

  gl_Position = mvp * ( vec4(pos,1.f) ) ;

  vTexCoord = gl_Position.xy;

  return nVertices;

}

// New models matrixes transformations
mat4 rotx(float a){
  mat4 rotationMatrix = mat4(1.);
  rotationMatrix[1][1] = cos(a);
  rotationMatrix[2][2] = cos(a);
  rotationMatrix[1][2] = -sin(a);
  rotationMatrix[2][1] = sin(a);
  return rotationMatrix;
}

mat4 roty(float a){
  mat4 rotationMatrix = mat4(1.);
  rotationMatrix[0][0] = cos(a);
  rotationMatrix[2][2] = cos(a);
  rotationMatrix[2][0] = -sin(a);
  rotationMatrix[0][2] = sin(a);
  return rotationMatrix;
}

mat4 rotz(float a){
  mat4 rotationMatrix = mat4(1.);
  rotationMatrix[0][0] = cos(a);
  rotationMatrix[1][1] = cos(a);
  rotationMatrix[0][1] = -sin(a);
  rotationMatrix[1][0] = sin(a);
  return rotationMatrix;
}

mat4 translate(float x, float y, float z){
  mat4 modelMatrix = mat4(1.);
  modelMatrix[3][0] = x;
  modelMatrix[3][1] = y;
  modelMatrix[3][2] = z;  
  return modelMatrix;
}

mat4 translate(vec3 vector){
  mat4 modelMatrix = mat4(1.);
  modelMatrix[3][0] = vector[0];
  modelMatrix[3][1] = vector[1];
  modelMatrix[3][2] = vector[2];  
  return modelMatrix;
}

mat4 scale(float x, float y, float z){
  mat4 modelMatrix = mat4(1.);
  modelMatrix[0][0] = x;
  modelMatrix[1][1] = y;
  modelMatrix[2][2] = z;  
  return modelMatrix;
}

// New transformations added to rotate around a point
mat4 rotx_round_point(float a, vec3 vector){
    return translate(vector[0],vector[1],vector[2])*rotx(a)*translate(-vector[0],-vector[1],-vector[2]);
}

mat4 roty_round_point(float a, vec3 vector){
    return translate(vector[0],vector[1],vector[2])*roty(a)*translate(-vector[0],-vector[1],-vector[2]);
}

mat4 rotz_round_point(float a, vec3 vector){
    return translate(vector[0],vector[1],vector[2])*rotz(a)*translate(-vector[0],-vector[1],-vector[2]);
}

uint walk(uint offset, mat4 vp){

  vec3 waistPoint = vec3(0, 10, 0);
  vec3 headPoint = vec3(0, 18, 0);
  vec3 neckPoint = vec3(0, 15, 0);
  vec3 leftFeetPoint = vec3(-2.5, 0, 0);
  vec3 rightFeetPoint = vec3(2.5, 0, 0);
  vec3 leftHandPoint = vec3(-6.5, 9, 0);
  vec3 rightHandPoint = vec3(6.5, 9, 0);

  vec3 symOffset = vec3(-0.5, -1, 0);

  mat4 torsoScale = scale(1, 7, 1);
  mat4 legScale = scale(10, 1, 0.7);
  mat4 waistScale = scale(1.4, 1.2, 1.3);
  mat4 armScale = scale(9, 1, 1);
  mat4 neckToHeadScale = scale(1, 4, 1);
  mat4 neckScale = scale(2, 0.7, 1);

  float normalizedHand = sin(iTime * 1)  * 0.5 + 0.5;
  float normalizedLeg = sin(iTime * 1) * 0.5 + 0.5;
  
  if (normalizedHand <= 0.5){ normalizedLeg = sin(-iTime * 1) * 0.5 + 0.5; }
  if (normalizedLeg <= 0.5){ normalizedLeg = sin(-iTime * 1) * 0.5 + 0.5; }
  
  float moveHand =  normalizedHand - 0.7;
  float moveLeftLeg =  normalizedLeg - 0.7;
  float moveRightLeg = -moveLeftLeg;

  //mat4 walkingModel = translate(0, 0, 0);
  
  mat4 walkingModel = translate(0, 0, walking);

  mat4 leftRotationModel = rotx_round_point(moveLeftLeg, waistPoint);
  mat4 rightRotationModel = rotx_round_point(moveRightLeg, waistPoint);
  mat4 moveArm = roty_round_point(moveHand, neckPoint);
  mat4 rightFeetRotation = rotx_round_point(-moveRightLeg, waistPoint);
  mat4 leftFeetRotation = rotx_round_point(-moveLeftLeg, waistPoint);

  uint torso = box(
    offset, 
    vp*walkingModel*translate( waistPoint + symOffset ) * torsoScale,
    10u,10u,4
  );  
  offset += torso;
  
  uint lLeg = box(
    offset, 
    vp*walkingModel*leftRotationModel*rotz_round_point(1.4, waistPoint)*translate( waistPoint )*legScale,
    10u,10u,4
  );    

  offset += lLeg;

  uint rLeg = box(
    offset, 
    vp*walkingModel*rightRotationModel*rotz_round_point(1.75, waistPoint)*translate( waistPoint + symOffset )*legScale,
    10u,10u,4
  ); 
  offset += rLeg;

  uint lArm = box(
    offset,vp*walkingModel*moveArm*rotz_round_point(2.3, neckPoint)*translate( neckPoint + symOffset )*armScale ,10u,10u,4
  );
  offset += lArm;

  uint lHand = sphere(
    offset,vp*walkingModel*moveArm*translate( leftHandPoint ),10u,10u,2
  );
  offset += lHand;

  uint rArm = box(
    offset,vp*walkingModel*moveArm*rotz_round_point(0.8, neckPoint)*translate( neckPoint )*armScale ,10u,10u,4
  );
  offset += rArm;

  uint rHand = sphere(
    offset,vp*walkingModel*moveArm*translate( rightHandPoint ),10u,10u,2
  );
  offset += rHand;

  uint neckBox = box(
    offset,vp*walkingModel*translate( neckPoint + symOffset ) * neckToHeadScale ,10u,10u,4
  );
  offset += neckBox;

  uint lFeet=sphere(
    offset,vp*walkingModel*leftFeetRotation*translate( leftFeetPoint ),10u,10u,2
  );
  offset+=lFeet;

  uint rFeet=sphere(
    offset,vp*walkingModel*rightFeetRotation*translate( rightFeetPoint ),10u,10u,2
  );
  offset+=rFeet;

  uint waist = sphere(
    offset,vp*walkingModel*translate( waistPoint ) * waistScale  ,10u,10u,2
  );
  offset+=waist;

  uint neck = sphere(
    offset,vp*walkingModel*translate( neckPoint ) * neckScale ,10u,10u,2
  );
  offset+=neck;

  uint head = sphere(
    offset,vp*walkingModel*translate( headPoint ),10u,10u,2
  );
  offset += head;

  return offset;
}

uint floor(uint offset, mat4 vp){
  int planeScale = 500;
  uint floorOne = box(
    offset,vp * translate(0,0,0) * scale(-planeScale,0.01,planeScale) ,10u,10u, 6
  );
  offset += floorOne;
  uint floorTwo = box(
    offset,vp * translate(0,0,0) * scale(planeScale,0.01,-planeScale) ,10u,10u,6
  );
  offset += floorTwo;
  uint floorThree = box(
    offset,vp * translate(0,0,0) * scale(planeScale,0.01,planeScale) ,10u,10u,6
  );
  offset += floorThree;
  uint floorFour = box(
    offset,vp * translate(0,0,0) * scale(-planeScale,0.01,-planeScale) ,10u,10u,6
  );
  offset += floorFour;


  uint floorFive = box(
    offset,vp * translate(0,0,0) * scale(-planeScale,0.02,planeScale) ,10u,10u, 7
  );
  offset += floorFive;

  uint floorSix = box(
    offset,vp * translate(0,0,0) * scale(planeScale,0.02,-planeScale) ,10u,10u,7
  );
  offset += floorSix;
  uint floorSeven = box(
    offset,vp * translate(0,0,0) * scale(planeScale,0.02,planeScale) ,10u,10u,7
  );
  offset += floorSeven;
  uint floorEight = box(
    offset,vp * translate(0,0,0) * scale(-planeScale,0.02,-planeScale) ,10u,10u,7
  );
  offset += floorEight;

  return offset;
}


void main(){
  gl_Position = vec4(0.f,0.f,0.f,1.f);
  mat4 vp = proj*view;

  uint offset = 0u;

  //offset = buildBody(offset, vp);

  offset += walk(offset, vp);
  offset += floor(offset, vp);

}
#endif



#ifdef FRAGMENT_SHADER
precision highp float;

in vec2 vTexCoord;
in vec3 vNormal;

out vec4 fColor;

flat in int material;

vec4 materialBody(){
  vec4 materialColorBody;
  if (material == 0) materialColorBody = vec4(1,1,0,1.f);
  if (material == 1) materialColorBody = vec4(0,1,0,1.f); 
  if (material == 2) materialColorBody = vec4(0,0.7,0.9,1.f); 
  if (material == 3) materialColorBody = vec4(1,1,1,1.f);  
  if (material == 4) materialColorBody = vec4(0,0,0,1.f);
  if (material == 5) materialColorBody = vec4(1,1,1,1.f);
  if (material == 6 || material == 7) materialColorBody = vec4(0.3,0.5,0.1,1.f);
  return materialColorBody;
}

vec4 applyLight(){
  vec3 N             = normalize(vNormal);
  vec3 L             = normalize(vec3(1));
  vec4 lightColor    = vec4(0.7); // Higher is brighter
  vec4 materialColorVector = materialBody();

  N *=  2.f*float(gl_FrontFacing)-1.f;

  float dF  = max(dot(N,L),0.2); // Lower is shadower
  vec3 D    = materialColorVector.xyz*lightColor.xyz*dF;
  vec3 A    = materialColorVector.xyz;

  fColor = vec4(A+D,1.f);

  return fColor;
}

void floorTexture(){

  if(material == 6){
    fColor = vec4(vec3(0.2,0.2,0.2), -sin(vTexCoord.x)+sin(vTexCoord.y)<0.8f);
  }
  if (material == 7){
    fColor = vec4(vec3(0,0,0.2), -sin(vTexCoord.x)+sin(vTexCoord.y)>0.8f);
  }

}

void applyTexture(){
  if(material == 6 || material == 7) floorTexture();
}

void main(){

  applyLight();
  applyTexture();
  
}

#endif
