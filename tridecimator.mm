#import <Cocoa/Cocoa.h>
#import "tridecimator.h"

int main(int argc, char *argv[]) {
  
  if(argc<3) {
    printf("Usage: tridecimator fileIn fileOut ratio\n");
    return -1;
  }

  NSString *src = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%s",argv[1]] encoding:NSUTF8StringEncoding error:nil];
  NSArray *lines = [src componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
  
  std::vector<float> v;
  std::vector<int> f;
  
  for(int k=0; k<lines.count; k++) {
    NSArray *arr = [lines[k] componentsSeparatedByCharactersInSet:whitespaces];
    if([arr count]>0) {
      if([arr[0] isEqualToString:@"v"]&&[arr count]>=4) {
        v.push_back([arr[1] doubleValue]);
        v.push_back([arr[2] doubleValue]);
        v.push_back([arr[3] doubleValue]);
      }
      else if([arr[0] isEqualToString:@"f"]&&[arr count]==4) {
        f.push_back([arr[1] doubleValue]-1);
        f.push_back([arr[2] doubleValue]-1);
        f.push_back([arr[3] doubleValue]-1);
      }
    }
  }

  tridecimator(&v,&f,(f.size()/3.0)*std::clamp(atof(argv[3]),0.1,1.0));

  NSMutableString *obj = [NSMutableString stringWithString:@""];
  for(unsigned int n=0; n<v.size()/3; n++) {
      [obj appendString:[NSString stringWithFormat:@"v %0.7f %0.7f %0.7f\n",v[n*3+0],v[n*3+1],v[n*3+2]]];
  }
  for(unsigned int n=0; n<f.size()/3; n++) {
    [obj appendString:[NSString stringWithFormat:@"f %d %d %d\n",f[n*3+0]+1,f[n*3+1]+1,f[n*3+2]+1]];
  }
  [obj writeToFile:[NSString stringWithFormat:@"%s",argv[2]] atomically:YES encoding:NSUTF8StringEncoding error:nil];
  
  return 0;
}