// stuff to define the mesh
#include <vcg/complex/complex.h>

// io
#include <wrap/io_trimesh/import.h>
#include <wrap/io_trimesh/export_obj.h>

// local optimization
#include <vcg/complex/algorithms/local_optimization.h>
#include <vcg/complex/algorithms/local_optimization/tri_edge_collapse_quadric.h>

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
    vcg::math::Quadric<double> &Qd() {return q;}
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
  
  if(argc<4) Usage();

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
  int FinalSize=mesh.fn*ratio;
  
  double TargetError = std::numeric_limits<double>::max();
  bool CleaningFlag = false;
  
  TriEdgeCollapseQuadricParameter qparams;
  qparams.QualityThr = 0.3;
  qparams.QualityCheck = false;
  qparams.HardQualityCheck = false; 
  qparams.NormalCheck = false;
  qparams.AreaCheck = false;
  qparams.OptimalPlacement = false;
  qparams.ScaleIndependent = false;
  qparams.PreserveBoundary = false;
  qparams.PreserveTopology = false;
  qparams.QualityQuadric = false;
  qparams.QualityWeight = false;
  
  // parse command line.
  for(int i=4; i<argc;) {
    if(argv[i][0]=='-') {
      switch(argv[i][1]) {
        case 'Q':
          qparams.QualityCheck = true;
          printf("Using Quality Checking\n");
          break;
        case 'H':
          qparams.HardQualityCheck = true;
          printf("Using HardQualityCheck Checking\n");
          break;
        case 'N':
          qparams.NormalCheck = true;
          printf("Using Normal Deviation Checking\n");
          break;
        case 'A':
          qparams.AreaCheck = true;
          printf("Using Area Checking\n");
          break;
        case 'O':
          qparams.OptimalPlacement = true;
          printf("Using OptimalPlacement\n"); 
          break;
        case 'S':
          qparams.ScaleIndependent = true;
          printf("Using ScaleIndependent\n"); 
          break;
        case 'B':
          qparams.PreserveBoundary = true;
          printf("Preserving Boundary\n");
          break;
        case 'T':
          qparams.PreserveTopology = true;
          printf("Preserving Topology\n");
          break;
        case 'P':
          qparams.QualityQuadric = true; 
          printf("Adding Quality Quadrics\n");
          break;
        case 'W': qparams.QualityWeight = true;
          printf("Using per vertex Quality as Weight\n");
          break;
        case 'p':
          qparams.QualityQuadricWeight = atof(argv[i]+2);
          printf("Setting QualityQuadricWeight factor to %f\n",qparams.QualityQuadricWeight);
          break;
        case 'w':
          qparams.QualityWeightFactor = atof(argv[i]+2);
          printf("Setting Quality Weight factor to %f\n",qparams.QualityWeightFactor);
          break;
        case 'q':
          qparams.QualityThr = atof(argv[i]+2);
          printf("Setting Quality Thr to %f\n",qparams.QualityThr);
          break;
        case 'h':
          qparams.HardQualityThr = atof(argv[i]+2);
          printf("Setting HardQuality Thr to %f\n",qparams.HardQualityThr);
          break;
        case 'n':
          qparams.NormalThrRad = math::ToRad(atof(argv[i]+2)); 
          printf("Setting Normal Thr to %f deg\n",qparams.NormalThrRad);
          break;
        case 'b':
          qparams.BoundaryQuadricWeight = atof(argv[i]+2);
          printf("Setting Boundary Weight to %f\n",qparams.BoundaryQuadricWeight); 
          break;
        case 'E':
          qparams.QuadricEpsilon = atof(argv[i]+2);
          printf("Setting QuadricEpsilon to %f\n",qparams.QuadricEpsilon); 
          break;
        case 'e':
          TargetError = atof(argv[i]+2);
          printf("Setting TargetError to %g\n",TargetError);
          break;
        case 'C':
          CleaningFlag=true;
          printf("Cleaning mesh before simplification\n");
          break;
        default:
          printf("Unknown option '%s'\n", argv[i]);
          exit(0);
      }
    }
    i++;
  }
  
  if(CleaningFlag) {
      int dup = tri::Clean<MyMesh>::RemoveDuplicateVertex(mesh);
      int unref = tri::Clean<MyMesh>::RemoveUnreferencedVertex(mesh);
      printf("Removed %i duplicate and %i unreferenced vertices from mesh \n",dup,unref);
  }
  
  printf("reducing it to %i\n",FinalSize);

  vcg::tri::UpdateBounding<MyMesh>::Box(mesh);

  // decimator initialization
  vcg::LocalOptimization<MyMesh> DeciSession(mesh,&qparams);

  int t1 = clock();
  DeciSession.Init<MyTriEdgeCollapse>();
  int t2 = clock();
  printf("Initial Heap Size %i\n",int(DeciSession.h.size()));

  DeciSession.SetTargetSimplices(FinalSize);
  DeciSession.SetTimeBudget(0.5f);
  DeciSession.SetTargetOperations(100000);
  if(TargetError< std::numeric_limits<float>::max()) DeciSession.SetTargetMetric(TargetError);

  while(DeciSession.DoOptimization()&&mesh.fn>FinalSize&&DeciSession.currMetric<TargetError) {
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