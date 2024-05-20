#import <Cocoa/Cocoa.h>
#import <vector>

namespace FileManager {
  
  bool exists(NSString *path) {
    static const NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *err = nil;
    [fileManager attributesOfItemAtPath:path error:&err];
    return (err)?false:true;
  }
  
  bool extension(NSString *str, NSString *ext) {
    return ([[str pathExtension] compare:ext]==NSOrderedSame)?true:false;
  }
  
  NSString *replace(NSString *str, NSString *from,NSString *to) {
    return [str stringByReplacingOccurrencesOfString:from withString:to];
  }
  
  NSString *replace(NSString *str,NSArray<NSString *> *from,NSString *to) {
    NSMutableString *mstr = [NSMutableString stringWithString:str];
    for(int n=0; n<[from count]; n++) {
      mstr.string = replace(mstr,from[n],to);
    }
    return [NSString stringWithString:mstr];
  }
  
  NSString *path(NSString *filename,NSString *identifier=nil) {
    if(identifier==nil) {
#if TARGET_OS_OSX
      return [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] bundlePath],filename];
#else
      return [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],filename];
#endif
    }
    else {
      return [NSString stringWithFormat:@"%@/%@",[[NSBundle bundleWithIdentifier:identifier] resourcePath],filename];
    }
  }
  
  NSURL *URL(NSString *path) {
    return [NSURL fileURLWithPath:path];
  }
}

typedef void (*FILTER)(std::vector<float> *, std::vector<unsigned int> *, NSString *);

int main(int argc, char *argv[]) {
  
  NSString *src = [NSString stringWithContentsOfFile:@"../mesh.obj" encoding:NSUTF8StringEncoding error:nil];
  NSArray *lines = [src componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
  
  std::vector<float> v;
  std::vector<unsigned int> f;
  
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
  
  int pluginPass = 4;
  NSString *pluginPath = @"../tridecimator.plugin";
  CFStringRef pluginFunctionName = (__bridge CFStringRef)(@"tridecimator");
  NSString *pluginParams = @"{\"ratio\":0.8}";
  
  if(pluginPath&&FileManager::exists(pluginPath)) {
    while(pluginPass--) {
      //NSLog(@"%d",pluginPass);
      CFBundleRef bundle = CFBundleCreate(kCFAllocatorDefault,(CFURLRef)[NSURL fileURLWithPath:pluginPath]);
      if(bundle) {
        FILTER filter = (FILTER)CFBundleGetFunctionPointerForName(bundle,pluginFunctionName);
        if(filter) {
          filter(&v,&f,pluginParams);
          if(bundle) {
            filter = nullptr;
            CFBundleUnloadExecutable(bundle);
            CFRelease(bundle);
          }
        }
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