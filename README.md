
# flutter_qrcode

A new flutter plugin project.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

### FLUTTER

you can depend on the flutter_qrcode plugin in your pubspec.yaml file
```groovy
  dependencies:
    ...
    nestedpageview: 
      git: https://github.com/zack-zjc/NestedPageView.git
```

### USAGE

```groovy
     NestedPageView(
        children:[
           NestedPageView(),
           NestedPageView(),  
                ...
        ]
      )
```


### FUNCTION

1.pageView嵌套使用。参考NestedScrollView实现触摸内外协调功能

2.自定义widget:NestedPageView,代码大部分拷贝PageView.实现了协调器Primary功能。

3.pageView内部类公开，继承extend_nested_page_view类里面实现协调器：NestedPageViewCoordinator，ChildPageScrollPosition，NestedPageController实现了自定义控制用户触摸事件