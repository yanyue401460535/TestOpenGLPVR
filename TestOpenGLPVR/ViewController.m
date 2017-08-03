//
//  ViewController.m
//  TestOpenGLPVR
//
//  Created by yanyue on 2017/8/1.
//  Copyright © 2017年 yanyue. All rights reserved.
//

#define SCREEN_WIDTH    ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT   ([[UIScreen mainScreen] bounds].size.height)

#define IMG_WIDTH 300
#define IMG_HEIGHT 300

#import "ViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <GLKit/GLKit.h>

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UIView *glView;
@property (nonatomic, strong) EAGLContext *glContext;
@property (nonatomic, strong) CAEAGLLayer *glLayer;
@property (nonatomic, assign) GLuint framebuffer;
@property (nonatomic, assign) GLuint colorRenderbuffer;
@property (nonatomic, assign) GLint framebufferWidth;
@property (nonatomic, assign) GLint framebufferHeight;
@property (nonatomic, strong) GLKBaseEffect *effect;
@property (nonatomic, strong) GLKTextureInfo *textureInfo;

@end

@implementation ViewController

- (void)setUpBuffers
{
    //set up frame buffer
    glGenFramebuffers(1, &_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    
    //set up color render buffer
    glGenRenderbuffers(1, &_colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderbuffer);
    [self.glContext renderbufferStorage:GL_RENDERBUFFER
                           fromDrawable:self.glLayer];
    glGetRenderbufferParameteriv(
                                 GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_framebufferWidth);
    glGetRenderbufferParameteriv(
                                 GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_framebufferHeight);
    //check success
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"Failed to make complete framebuffer object: %i",
              glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

- (void)tearDownBuffers
{
    if (_framebuffer)
    {
        //delete framebuffer
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_colorRenderbuffer)
    {
        //delete color render buffer
        glDeleteRenderbuffers(1, &_colorRenderbuffer);
        _colorRenderbuffer = 0;
    }
}

- (void)drawFrame
{
    //bind framebuffer & set viewport
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glViewport(0, 0, _framebufferWidth, _framebufferHeight);
    
    //bind shader program
    [self.effect prepareToDraw];
    
    //clear the screen
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(0.0, 0.0, 0.0, 0.0);
    
    //set up vertices,Scall To Fill
//    GLfloat vertices[] =
//    {
//        -1.0f, -1.0f,
//        -1.0f, 1.0f,
//        1.0f, 1.0f,
//        1.0f, -1.0f
//    };
    
    float right =IMG_WIDTH/SCREEN_WIDTH;
    float top = IMG_HEIGHT/SCREEN_HEIGHT;
    
    //set up vertices,根据屏幕宽高，以及设定需要显示的图片宽高（即：IMG_WIDTH，IMG_HEIGHT)，自动算出居中的vertices
    GLfloat vertices[] =
    {
        -right, -top,//左下
        -right, top,//左上
        right, top,//右上
        right, -top//右下
    };
    
    //set up colors
    GLfloat texCoords[] =
    {
        0.0f, 1.0f,//左上
        0.0f, 0.0f,//左下
        1.0f, 0.0f,//右下
        1.0f, 1.0f//右上
    };
    
    /*
     可以看出，vertices和texCoords的坐标是上下翻转的（绕x轴翻转），以为如果不设置GLKTextureLoaderOriginBottomLeft为YES的话，纹理坐标系是反的。
     如果这段代码这么设置，就不需要设置成翻转的坐标，但会报GLKTextureLoaderErrorReorientationFailure错误，至于错误原因，我还没有找到，如果知道解决方法，辛苦告诉我下哈
     
     NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];
     NSError *error = nil;
     self.textureInfo = [GLKTextureLoader textureWithContentsOfFile:imageFile
     options:options
     error:&error];
     if (error)
     {
        NSLog(@"ERROR: loading texture: %@", [error localizedDescription]);
     }
     */
    
    //draw triangle
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribPosition, 2,
                          GL_FLOAT, GL_FALSE, 0, vertices);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2,
                          GL_FLOAT, GL_FALSE, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    //present render buffer
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [self.glContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //set up context
    self.glContext =
    [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.glContext];
    
    //set up layer
    self.glLayer = [CAEAGLLayer layer];
    self.glLayer.frame = self.glView.bounds;
    self.glLayer.opaque = NO;
    [self.glView.layer addSublayer:self.glLayer];
    self.glLayer.drawableProperties =
    @{kEAGLDrawablePropertyRetainedBacking: @NO,
      kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
    
    //load texture
    glActiveTexture(GL_TEXTURE0);
    NSString *imageFile = [[NSBundle mainBundle] pathForResource:@"testPVRTC4"
                                                          ofType:@"pvr"];
    if (imageFile == nil)
    {
        NSLog(@"ERROR:image not found");
    }
    NSError *error = nil;
    

    self.textureInfo = [GLKTextureLoader textureWithContentsOfFile:imageFile
                                                               options:nil
                                                                 error:&error];
    
    if (error)
    {
        NSLog(@"ERROR: loading texture: %@", [error localizedDescription]);
    }
    
    //create texture
    GLKEffectPropertyTexture *texture =
    [[GLKEffectPropertyTexture alloc] init];
    texture.enabled = YES;
    texture.envMode = GLKTextureEnvModeDecal;
    texture.name = self.textureInfo.name;

    
    //set up base effect
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.texture2d0.name = texture.name;
    

    //set up buffers
    [self setUpBuffers];
    
    
    //draw frame
    [self drawFrame];
   
}

- (void)viewDidUnload
{
    [self tearDownBuffers];
    [super viewDidUnload];
}

- (void)dealloc
{
    [self tearDownBuffers];
    [EAGLContext setCurrentContext:nil];
}


@end
