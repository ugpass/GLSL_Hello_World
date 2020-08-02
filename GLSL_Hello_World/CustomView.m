//
//  CustomView.m
//  GLSL_Hello_World
//
//  Created by William on 2020/7/29.
//  Copyright © 2020 ls. All rights reserved.
//

#import "CustomView.h"
#import <OpenGLES/ES2/gl.h>

/**
 1.创建图层
 2.创建上下文
 3.清空缓冲区
 4.设置renderBuffer
 5.设置frameBuffer
 6.开始绘制
 */

@interface CustomView()

@property (nonatomic, strong) CAEAGLLayer *eaglLayer;//自定义图层

@property (nonatomic, strong) EAGLContext *context;//上下文

@property (nonatomic, assign) GLuint renderBuffer;//渲染缓冲区ID
@property (nonatomic, assign) GLuint frameBuffer;//帧缓冲区ID

@property (nonatomic, assign) GLuint program;//程序ID

@end

@implementation CustomView

- (void)layoutSubviews {
    [self setupLayer];
    [self setupContext];
    [self clearRenderAndFrameBuffer];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    
    [self renderLayer];
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

//1.设置图层
- (void)setupLayer {
    self.eaglLayer = (CAEAGLLayer *)self.layer;
    
    [self setContentScaleFactor:[UIScreen mainScreen].scale];
    
    /**
     kEAGLDrawablePropertyColorFormat:颜色缓冲区格式
     kEAGLDrawablePropertyRetainedBacking:绘制后是否保留其内容
     */
    self.eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false, kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

//2.设置上下文
- (void)setupContext {
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"create context failed");
        return;
    }
    BOOL ret = [EAGLContext setCurrentContext:self.context];
    if (!ret) {
        NSLog(@"setCurrentContext failed");
        return;
    }
}

//3.清空缓冲区
- (void)clearRenderAndFrameBuffer {
    //Frame Buffer Object FBO
    //Render Buffer 三类：颜色缓冲区、深度缓冲区、模版缓冲区
    
    glDeleteRenderbuffers(1, &_renderBuffer);
    self.renderBuffer = 0;
    
    glDeleteFramebuffers(1, &_frameBuffer);
    self.frameBuffer = 0;
}

//4.设置renderBuffer
- (void)setupRenderBuffer {
    GLuint renderBuffer;
    
    glGenRenderbuffers(1, &renderBuffer);
    
    self.renderBuffer = renderBuffer;
    
    glBindRenderbuffer(GL_RENDERBUFFER, self.renderBuffer);
    
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglLayer];
}

//5.设置frameBuffer
- (void)setupFrameBuffer {
    GLuint frameBuffer;
    
    glGenFramebuffers(1, &frameBuffer);
    
    self.frameBuffer = frameBuffer;
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.frameBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.renderBuffer);
}

//6.开始绘制
- (void)renderLayer {
    //设置背景色
    glClearColor(0.45, 0.5, 0, 1);
    //清空颜色缓冲区
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [UIScreen mainScreen].scale;
    //设置视口
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    //顶点着色器和片元着色器文件路径
    NSString *vertFilePath = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fragFilePath = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    
    //加载顶点着色器和纹理着色器 创建program
    self.program = [self loaderShader:vertFilePath withFrag:fragFilePath];
    
    //链接program
    glLinkProgram(self.program);
    
    //获取program链接状态
    GLint linkStatus;
    glGetProgramiv(self.program, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLchar loginfo[512];
        glGetProgramInfoLog(self.program, sizeof(loginfo), 0, &loginfo[0]);
        NSString *message = [NSString stringWithUTF8String:loginfo];
        NSLog(@"program link error:%@", message);
        return;
    }
    
    //使用program
    glUseProgram(self.program);
    
    //准备顶点数据/纹理坐标
    GLfloat attrArr[] =
     {
         0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
         -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
         -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,
         
         0.5f, 0.5f, -1.0f,      1.0f, 1.0f,
         -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
         0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
     };
    
    //将顶点坐标和纹理坐标拷贝到GPU中
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    //获取顶点数据通道ID v.sh positon 打开顶点通道 并设置数据读取方式
    GLuint position = glGetAttribLocation(self.program, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    
    //打开纹理通道 并设置数据读取方式
    GLuint textCoordinate = glGetAttribLocation(self.program, "textCoordinate");
    glEnableVertexAttribArray(textCoordinate);
    glVertexAttribPointer(textCoordinate, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);

    //加载纹理
    [self setupTexture:@"mew_progressive.jpg"];
    
    //设置纹理采样器
    glUniform1i(glGetUniformLocation(self.program, "colorMap"), 0);
    
    //开始绘制
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    //从渲染缓冲区显示到屏幕上
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

//加载纹理
- (GLuint)setupTexture:(NSString *)filePath {
    //获取图像CGImage
    CGImageRef cgImage = [UIImage imageNamed:filePath].CGImage;
    if (!cgImage) {
        NSLog(@"faile to load image");
        return -1;
    }
    
    //获取图片宽高
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    //获取图片字节数 宽*高*4（RGBA）
    GLubyte *data = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    //创建上下文
    /*
     参数1：data,指向要渲染的绘制图像的内存地址
     参数2：width,bitmap的宽度，单位为像素
     参数3：height,bitmap的高度，单位为像素
     参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
     参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
     参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
     */
    CGContextRef cgContext = CGBitmapContextCreate(
                                                   data,
                                                   width,
                                                   height,
                                                   8,
                                                   width * 4,
                                                   CGImageGetColorSpace(cgImage),
                                                   kCGImageAlphaPremultipliedLast);
    //使用CGContextRef 将图片绘制出来 也是一个解码的过程
    /*
     CGContextDrawImage 使用的是Core Graphics框架，坐标系与UIKit 不一样。UIKit框架的原点在屏幕的左上角，Core Graphics框架的原点在屏幕的左下角。
     CGContextDrawImage
     参数1：绘图上下文
     参数2：rect坐标
     参数3：绘制的图片
     */
    CGRect rect = CGRectMake(0, 0, width, height);
    
    CGContextDrawImage(cgContext, rect, cgImage);
    
    CGContextRelease(cgContext);
    
    //纹理 当只有一个纹理时 纹理ID为0, 多个纹理需要激活
    GLuint textureID;
    glGenTextures(1, &textureID);
    
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    //设置纹理属性
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    //载入纹理2D数据
    /*
     参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
     参数2：加载的层次，一般设置为0
     参数3：纹理的颜色值GL_RGBA
     参数4：宽
     参数5：高
     参数6：border，边界宽度
     参数7：format
     参数8：type
     参数9：纹理数据
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    free(data);
    return 0;
}

#pragma mark - shader
//加载着色器
- (GLuint)loaderShader:(NSString *)vert withFrag:(NSString *)frag {
    //顶点着色器对象 片元着色器对象/句柄
    GLuint verShader, fragShader;
    
    //创建空的program
    GLuint program = glCreateProgram();
    
    //编译
    [self compileShader:&verShader type:GL_VERTEX_SHADER filePath:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER filePath:frag];
    
    //把shader附着 到编译好的程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //附着之后 就可以删除
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

//编译
- (void)compileShader:(GLuint *)shader type:(GLenum)type filePath:(NSString *)filePath {
    //读取路径
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    const GLchar *source = [content UTF8String];
    
    //创建对应类型的shader
    *shader = glCreateShader(type);
    
    //将着色器附着到 着色器对象上
    glShaderSource(*shader, 1, &source, NULL);
    
    //编译
    glCompileShader(*shader);
}

@end
