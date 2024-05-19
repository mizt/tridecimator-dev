#import <Cocoa/Cocoa.h>

// stuff to define the mesh
#import <vcg/complex/complex.h>

// io
#import <wrap/io_trimesh/import.h>
#import <wrap/io_trimesh/export_obj.h>

// local optimization
#import <vcg/complex/algorithms/local_optimization.h>
#import <vcg/complex/algorithms/local_optimization/tri_edge_collapse_quadric.h>

#include <vcg/complex/algorithms/clean.h>

using namespace vcg;
using namespace tri;

/**********************************************************
Mesh Classes for Quadric Edge collapse based simplification

For edge collpases we need verteses with:
- V->F adjacency
- per vertex incremental mark
- per vertex Normal


Moreover for using a quadric based collapse the vertex class
must have also a Quadric member Q();
Otherwise the user have to provide an helper function object
to recover the quadric.

******************************************************/
// The class prototypes.
class MyVertex;
class MyEdge;
class MyFace;

struct MyUsedTypes: public UsedTypes<Use<MyVertex>::AsVertexType,Use<MyEdge>::AsEdgeType,Use<MyFace>::AsFaceType> {};

class MyVertex : public Vertex<MyUsedTypes, vertex::VFAdj, vertex::Coord3f, vertex::Mark, vertex::Qualityf, vertex::BitFlags> {
  public:
    vcg::math::Quadric<double> &Qd() { return q; }
  private:
    math::Quadric<double> q;
};

class MyEdge : public Edge< MyUsedTypes> {};

typedef BasicVertexPair<MyVertex> VertexPair;
class MyFace : public Face<MyUsedTypes, face::VFAdj, face::VertexRef, face::BitFlags> {};

// the main mesh class
class MyMesh : public vcg::tri::TriMesh<std::vector<MyVertex>,std::vector<MyFace>> {};

class MyTriEdgeCollapse: public vcg::tri::TriEdgeCollapseQuadric<MyMesh, VertexPair, MyTriEdgeCollapse, QInfoStandard<MyVertex>> {
  public:
    typedef  vcg::tri::TriEdgeCollapseQuadric<MyMesh, VertexPair, MyTriEdgeCollapse, QInfoStandard<MyVertex>> TECQ;
    typedef  MyMesh::VertexType::EdgeType EdgeType;
    inline MyTriEdgeCollapse(const VertexPair &p, int i, BaseParameterClass *pp) : TECQ(p,i,pp) {}
};

void Usage() {
    printf("Usage: tridecimator fileIn fileOut face_num [opt]\n");
    exit(-1);
}

int main(int argc, char *argv[]) {
  
  if(argc<3) Usage();

  MyMesh mesh;
  
  int err = vcg::tri::io::Importer<MyMesh>::Open(mesh,argv[1]);
  if(err) {
    printf("Unable to open mesh %s : '%s'\n",argv[1],vcg::tri::io::Importer<MyMesh>::ErrorMsg(err));
    exit(-1);
  }
  printf("mesh loaded %d %d \n",mesh.vn,mesh.fn);
  
  float ratio = atof(argv[3]);
  if(ratio>=1.0) ratio = 1.0;
  else if(ratio<=0.1) ratio = 0.1;
  int TargetFaceNum=mesh.fn*ratio;
  
  double TargetError = std::numeric_limits<double>::max();
  
  bool CleaningFlag = true;
  
  TriEdgeCollapseQuadricParameter qparams;
  qparams.BoundaryQuadricWeight = 0.500000;
  qparams.FastPreserveBoundary = false;
  qparams.AreaCheck = false;
  qparams.HardQualityCheck = false;
  qparams.HardQualityThr = 0.100000;
  qparams.HardNormalCheck = false;
  qparams.NormalCheck = false;
  qparams.NormalThrRad = M_PI/2.0;
  qparams.CosineThr = 0.000000; // ~ cos(pi/2)
  qparams.OptimalPlacement = true;
  qparams.SVDPlacement = false;
  qparams.PreserveTopology = false;
  qparams.PreserveBoundary = false;
  qparams.QuadricEpsilon = 1e-15;
  qparams.QualityCheck = true;
  qparams.QualityThr = 0.300000;  // Collapsed that generate faces with quality LOWER than this value are penalized. So higher the value -> better the quality of the accepted triangles
  qparams.QualityQuadric = false; // During the initialization manage all the edges as border edges adding a set of additional quadrics that are useful mostly for keeping face aspect ratio good.
  qparams.QualityQuadricWeight = 0.001000; // During the initialization manage all the edges as border edges adding a set of additional quadrics that are useful mostly for keeping face aspect ratio good.
  qparams.QualityWeight = false;
  qparams.QualityWeightFactor = 100.000000;
  qparams.ScaleFactor = 1.000000;
  qparams.ScaleIndependent = true;
  qparams.UseArea = true;
  qparams.UseVertexWeight = false;
  
  if(CleaningFlag) {
      int dup = tri::Clean<MyMesh>::RemoveDuplicateVertex(mesh);
      int unref = tri::Clean<MyMesh>::RemoveUnreferencedVertex(mesh);
      printf("Removed %i duplicate and %i unreferenced vertices from mesh \n",dup,unref);
  }
  
  printf("reducing it to %i\n",TargetFaceNum);

  vcg::tri::UpdateBounding<MyMesh>::Box(mesh);

  // decimator initialization
  vcg::LocalOptimization<MyMesh> DeciSession(mesh,&qparams);

  int t1 = clock();
  DeciSession.Init<MyTriEdgeCollapse>();
  int t2 = clock();
  printf("Initial Heap Size %i\n",int(DeciSession.h.size()));

  DeciSession.SetTargetSimplices(TargetFaceNum);
  DeciSession.SetTimeBudget(0.1f); // this allows updating the progress bar 10 time for sec...
  //DeciSession.SetTargetOperations(100000);

  if(TargetError< std::numeric_limits<float>::max()) DeciSession.SetTargetMetric(TargetError);

  while(DeciSession.DoOptimization()&&mesh.fn>TargetFaceNum&&DeciSession.currMetric<TargetError) {
    printf("Current Mesh size %7i heap sz %9i err %9g \n",mesh.fn, int(DeciSession.h.size()),DeciSession.currMetric);
  }
  
  int t3 = clock();
  printf("mesh %d %d Error %g \n",mesh.vn,mesh.fn,DeciSession.currMetric);
  printf("Completed in (%5.3f+%5.3f) sec\n",float(t2-t1)/CLOCKS_PER_SEC,float(t3-t2)/CLOCKS_PER_SEC);
  unsigned int mask = 0;
  mask|=vcg::tri::io::Mask::IOM_VERTCOORD;
  mask|=vcg::tri::io::Mask::IOM_FACEINDEX;
  vcg::tri::io::ExporterOBJ<MyMesh>::Save(mesh,argv[2],mask);
    
  return 0;
}