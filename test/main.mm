#import <Cocoa/Cocoa.h>
#import <vector>

typedef int (*FILTER)(std::vector<float> *, std::vector<int> *, NSString *);

int main(int argc, char *argv[]) {
  
  NSString *src = [NSString stringWithContentsOfFile:@"../src.obj" encoding:NSUTF8StringEncoding error:nil];
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
  
  CFBundleRef bundle = CFBundleCreate(kCFAllocatorDefault,(CFURLRef)[NSURL fileURLWithPath:@"../tridecimator.plugin"]);
  if(bundle) {
    //NSLog(@"%@",bundle);
    FILTER filter = (FILTER)CFBundleGetFunctionPointerForName(bundle,CFSTR("tridecimator"));
    if(filter) {
      filter(&v,&f,@"{\"ratio\":0.1}");
      if(bundle) {
        filter = nullptr;
        CFBundleUnloadExecutable(bundle);
        CFRelease(bundle);
      }
    }
  }
  
  NSMutableString *obj = [NSMutableString stringWithString:@""];
  for(unsigned int n=0; n<v.size()/3; n++) {
      [obj appendString:[NSString stringWithFormat:@"v %0.7f %0.7f %0.7f\n",v[n*3+0],v[n*3+1],v[n*3+2]]];
  }
  for(unsigned int n=0; n<f.size()/3; n++) {
    [obj appendString:[NSString stringWithFormat:@"f %d %d %d\n",f[n*3+0]+1,f[n*3+1]+1,f[n*3+2]+1]];
  }
  [obj writeToFile:@"dst.obj" atomically:YES encoding:NSUTF8StringEncoding error:nil];
  
  return 0;
}