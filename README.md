Lite_dual-CPU（文档更新中）
=============

本项目为本人于2022年参加第六届‘龙芯杯’个人赛的作品。 由于个人能力和时间缘故，该项目并不能通过大赛的全部评测，在时序收敛的情况下，CPU核在访存阶段对指令SRAM发起读取时数据读出不稳定（可能是建立时间余量太少导致），因此叫‘Lite’-CPU。如果后续学到了相关的知识、有时间，我希望能够尽力优化与完善这个设计。如果想看能够完整通过‘龙芯杯’评测的作品，请移步本人五段流水线CPU项目(还未上传)。



项目特征
---------------

顺序双发射处理器

七级流水线

写直达指令cache与数据cache



参考资料说明
-----

本设计使用大赛发布的模板工程文件。CPU设计代码参考了雷思磊的五级流水线OpenMIPS，沿用其部分命名格式以及数据通路。在此基础上参考姚永斌的超标量处理器设计中的多发射设计思路，实现了双发射结构。除此之外，本项目中的cache设计`借鉴UltraMIPS_NSCSCC项目与CPU设计实战中的设计思路`。指令buffer设计代码`借鉴FDU1.1-NSCSCC项目中的设计思路`。

参考项目：
---------

1.FDU1.1-NSCSCC [https://github.com/liuweidin/FDU1.1-NSCSCC ](https://github.com/NSCSCC-2020-Fudan/FDU1.1-NSCSCC)

2.UltraMIPS_NSCSCC https://github.com/SocialistDalao/UltraMIPS_NSCSCC

3.雷思磊. 自己动手写CPU. 电子工业出版社

4.姚永斌. 超标量处理器设计. 清华大学出版社

5.胡伟武. CPU设计实战. 机械工业出版社






