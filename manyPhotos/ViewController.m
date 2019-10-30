//
//  ViewController.m
//  manyPhotos
//
//  Created by Alexey Ternopolsky on 29/10/2019.
//  Copyright © 2019 Alexey Ternopolsky. All rights reserved.
//

@import Photos;

#import "ViewController.h"
#import "AppDelegate.h"

static const NSInteger kMaxPhotoCount = 1000;

@interface ViewController () {
    NSInteger photoCounter;
    UIImage * imageToAdd;
    NSInteger totalPhotoCount;
}

@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *photoCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fillPhotoCount) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self fillPhotoCount];
}

- (IBAction)onAddPhoto:(id)sender {
    photoCounter = 0;
    imageToAdd = [UIImage imageNamed:@"Photo"];
    self.progressView.hidden = NO;
    self.progressView.progress = 0;
    [self.addButton setEnabled:NO];
    [self image:nil didFinishSavingWithError:nil contextInfo:nil];
}

- (IBAction)removePhotos:(id)sender {
    imageToAdd = [UIImage imageNamed:@"Photo"];
    PHFetchResult<PHAssetCollection *> * result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                                              subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                                                              options:nil];
       
       if (result.count > 0) {
           PHAssetCollection * collection = [result objectAtIndex:0];
           
           PHFetchOptions * options = [PHFetchOptions new];
           NSInteger width = CGImageGetWidth(imageToAdd.CGImage);
           NSInteger heigth = CGImageGetHeight(imageToAdd.CGImage);
           options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d && pixelWidth == %d && pixelHeight == %d", PHAssetMediaTypeImage, width, heigth];
           PHFetchResult<PHAsset *> * result = [PHAsset fetchAssetsInAssetCollection:collection options:options];
           NSMutableArray * objects = [NSMutableArray new];
           for (NSInteger index = 0; index < result.count; index++) {
               PHAsset * asset = [result objectAtIndex:index];
               [objects addObject:asset];
           }
           
           [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
               [PHAssetChangeRequest deleteAssets:objects];
           } completionHandler:^(BOOL success, NSError *error) {
               UIAlertController * controler = [UIAlertController alertControllerWithTitle:@"Done" message:error != nil ? @"FAILURE" : @"All images have been deleted." preferredStyle:UIAlertControllerStyleAlert];
               [controler addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
               [self presentViewController:controler animated:YES completion:nil];
           }];
       };
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    self.progressView.progress = 1.0f * photoCounter / kMaxPhotoCount;
    if (photoCounter < kMaxPhotoCount && error == nil) {
        totalPhotoCount++;
        [self updatePhotoCountText];
        photoCounter++;
        UIImageWriteToSavedPhotosAlbum(imageToAdd, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    } else {
        self.progressView.hidden = YES;
        self.addButton.enabled = YES;
        UIAlertController * controler = [UIAlertController alertControllerWithTitle:@"Done" message:error != nil ? @"FAILURE" : @"Photos added! Test how many you can add before fill all your storage." preferredStyle:UIAlertControllerStyleAlert];
        [controler addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:controler animated:YES completion:nil];
        [self fillPhotoCount];
    }
}

- (void)fillPhotoCount {
    PHFetchResult<PHAssetCollection *> * result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                                                 subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                                                                 options:nil];
    if (result.count > 0) {
        PHAssetCollection * collection = [result objectAtIndex:0];
        PHFetchResult<PHAsset *> * result = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
        totalPhotoCount = result.count;
        [self updatePhotoCountText];
    };
}

- (void)updatePhotoCountText {
    self.photoCount.text = [NSString stringWithFormat:@"Items in camera roll = %@", @(totalPhotoCount)];
}

@end
