//
//  AMapMarkerController.m
//  amap_flutter_map
//
//  Created by lly on 2020/11/3.
//

#import "AMapMarkerController.h"
#import "AMapMarker.h"
#import "AMapJsonUtils.h"
#import "AMapConvertUtil.h"
#import "MAAnnotationView+Flutter.h"
#import "FlutterMethodChannel+MethodCallDispatch.h"

@interface AMapMarkerController ()

@property (nonatomic,strong) NSMutableDictionary<NSString*,AMapMarker*> *markerDict;
@property (nonatomic,strong) FlutterMethodChannel *methodChannel;
@property (nonatomic,strong) NSObject<FlutterPluginRegistrar> *registrar;
@property (nonatomic,strong) MAMapView *mapView;

@end

@implementation AMapMarkerController

- (instancetype)init:(FlutterMethodChannel*)methodChannel
             mapView:(MAMapView*)mapView
           registrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    self = [super init];
    if (self) {
        _methodChannel = methodChannel;
        _mapView = mapView;
        _markerDict = [NSMutableDictionary dictionaryWithCapacity:1];
        _registrar = registrar;
        
        __weak typeof(self) weakSelf = self;
        [_methodChannel addMethodName:@"markers#update" withHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
            id markersToAdd = call.arguments[@"markersToAdd"];
            if ([markersToAdd isKindOfClass:[NSArray class]]) {
                [weakSelf addMarkers:markersToAdd];
            }
            id markersToChange = call.arguments[@"markersToChange"];
            if ([markersToChange isKindOfClass:[NSArray class]]) {
                [weakSelf changeMarkers:markersToChange];
            }
            id markerIdsToRemove = call.arguments[@"markerIdsToRemove"];
            if ([markerIdsToRemove isKindOfClass:[NSArray class]]) {
                [weakSelf removeMarkerIds:markerIdsToRemove];
            }
            result(nil);
        }];
    }
    return self;
}

- (nullable AMapMarker *)markerForId:(NSString *)markerId {
    return _markerDict[markerId];
}

- (void)addMarkers:(NSArray*)markersToAdd {
    for (NSDictionary* marker in markersToAdd) {
        AMapMarker *markerModel = [AMapJsonUtils modelFromDict:marker modelClass:[AMapMarker class]];
        //???bitmapDesc?????????UIImage
        if (markerModel.icon) {
            markerModel.image = [AMapConvertUtil imageFromRegistrar:self.registrar iconData:markerModel.icon];
        }
        // ???????????????????????????????????????????????????????????????????????????marker??????
        if (markerModel.id_) {
            _markerDict[markerModel.id_] = markerModel;
        }
        [self.mapView addAnnotation:markerModel.annotation];
         //[self.mapView selectAnnotation:mapView.annotation animated:true];
         //[self.mapView showAnnotations:annotations animated:YES];
    }
}

- (void)changeMarkers:(NSArray*)markersToChange {
    for (NSDictionary* markerToChange in markersToChange) {
        NSLog(@"changeMarker:%@",markerToChange);
        AMapMarker *markerModelToChange = [AMapJsonUtils modelFromDict:markerToChange modelClass:[AMapMarker class]];
        AMapMarker *currentMarkerModel = _markerDict[markerModelToChange.id_];
        NSAssert(currentMarkerModel != nil, @"???????????????marker?????????");
        
        //???????????????????????????????????????????????????
        if ([AMapConvertUtil checkIconDescriptionChangedFrom:currentMarkerModel.icon to:markerModelToChange.icon]) {
            UIImage *image = [AMapConvertUtil imageFromRegistrar:self.registrar iconData:markerModelToChange.icon];
            currentMarkerModel.icon = markerModelToChange.icon;
            currentMarkerModel.image = image;
        }
        //???????????????????????????????????????
        [currentMarkerModel updateMarker:markerModelToChange];
        
        MAAnnotationView *view = [self.mapView viewForAnnotation:currentMarkerModel.annotation];
        if (view) {//?????????????????????View??????????????????
            [view updateViewWithMarker:currentMarkerModel];
        } //????????????????????????viewDidAdd???????????????????????????view????????????
    }
}

- (void)removeMarkerIds:(NSArray*)markerIdsToRemove {
    for (NSString* markerId in markerIdsToRemove) {
        if (!markerId) {
            continue;
        }
        AMapMarker* marker = _markerDict[markerId];
        if (!marker) {
            continue;
        }
        [self.mapView removeAnnotation:marker.annotation];
        [_markerDict removeObjectForKey:markerId];
    }
}

//MARK: Marker?????????

- (BOOL)onMarkerTap:(NSString*)markerId {
  if (!markerId) {
    return NO;
  }
  AMapMarker* marker = _markerDict[markerId];
  if (!marker) {
    return NO;
  }
  [_methodChannel invokeMethod:@"marker#onTap" arguments:@{@"markerId" : markerId}];
  return YES;
}

- (BOOL)onMarker:(NSString *)markerId endPostion:(CLLocationCoordinate2D)position {
    if (!markerId) {
      return NO;
    }
    AMapMarker* marker = _markerDict[markerId];
    if (!marker) {
      return NO;
    }
    [_methodChannel invokeMethod:@"marker#onDragEnd"
                         arguments:@{@"markerId" : markerId, @"position" : [AMapConvertUtil jsonArrayFromCoordinate:position]}];
    return YES;
}

//- (BOOL)onInfoWindowTap:(NSString *)markerId {
//    if (!markerId) {
//      return NO;
//    }
//    AMapMarker* marker = _markerDict[markerId];
//    if (!marker) {
//      return NO;
//    }
//    [_methodChannel invokeMethod:@"infoWindow#onTap" arguments:@{@"markerId" : markerId}];
//    return YES;
//}



@end
