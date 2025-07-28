# 🚀 FPGA 기반 노이즈 제거 필터 IP 설계 프로젝트

본 프로젝트는 3x3 윈도우 기반 영상 노이즈 제거 필터를 Verilog로 설계하고,
Zynq 기반 보드에서 실시간 영상 스트리밍 파이프라인을 구현한 사례입니다.


---


## 🔧 사용 기술 및 툴

- Vivado 2022.2, Verilog HDL
- AXI4-Stream 프로토콜
- Zynq-7000 (Zybo Z7-20)
- ILA, VDMA, FSM, 파이프라인 처리 기법
- Custom HW IP 설계 및 디버깅


---


## 💡 프로젝트 목표

- **실시간 영상 필터링**을 위한 **커스텀 HW IP**를 직접 설계
- AXI4-Stream 프로토콜을 이용해 **VDMA ↔ HW IP ↔ HDMI 출력** 파이프라인 구성
- **FSM과 파이프라인 설계**를 통해 타이밍 정합 및 출력 정합성 확보


---


## 📌 주요 기능 및 설계 개요

- 입력: 1920x1080, 30fps RGB 스트림
- 처리: 3x3 평균 기반 노이즈 제거
- 출력: HDMI (VDMA Read → Video Out)
- 주요 처리 방식:
  - Line Buffer (3줄)
  - Valid & Ready 핸드쉐이크 제어
  - TLAST / TUSER 처리
  - FSM 기반 동기화


---


## ⚙️ 구현 흐름도
![image](docs/denoise_ip_block_diagram.png)
![image](docs/Block_Diagram.jpg)
[Block Diagram.pdf](https://github.com/user-attachments/files/21471468/Block.Diagram.pdf)

---


## 🧠 개발 중 해결한 문제와 기술적 인사이트

### 📍 문제1: TLAST/TUSER 스트라이프 발생  
- **원인:** 파이프라인 처리 시 TUSER 위치가 frame 시작점과 mismatch  
- **해결:** FSM과 `pixel_x/pixel_y` 카운터, 타이밍 딜레이 파이프라인 적용

### 📍 문제2: VDMA circular mode에서 sync mismatch  
- **원인:** MM2S interrupt 미발생으로 TUSER generation 실패  
- **해결:** MM2S interrupt 기반 FSM 설계 후, 정확한 frame 시작점 맞춤

### 📍 문제3: Verilog 핸드쉐이크 타이밍 위반  
- **원인:** m_axis_tready에 따른 tvalid 제어 미흡  
- **해결:** `(!m_axis_tvalid || m_axis_tready)` 논리 적용으로 AXI4-Stream 준수

> 이러한 문제 해결 과정을 통해 실제 SoC 파이프라인 설계에서 필요한
> **시퀀셜 타이밍, 핸드쉐이크 흐름 제어, FSM 상태관리**에 대한 깊은 이해를 얻었습니다.


---


## 🖼️ 결과 이미지 및 디버깅 사진

> 📅 [2025-04-08]  
> **문제:** 영상이 아래로 두 줄 밀려 출력됨
> **해결:** TUSER 위치 FSM 정렬 후 정상 출력
> ![image](progress/2025-04-08/picture/(문제)상단_스트라이프 패턴.png)


---


## 📁 자료

- [`src/`](src): Verilog 소스
- [`docs/`](docs): 문제 해결 과정 문서 + 사진
- [`project_archive/`](project_archive): 날짜별 Vivado 프로젝트 ZIP


---


## ✍️ 한마디

해당 프로젝트는 단순한 RTL 설계를 넘어서,  
**"시스템 전체를 설계하고 디버깅하며 구조적 사고와 문제 해결 능력"**을 길렀던 경험입니다.


---


## 📌 GitHub Pages 문서 바로가기

👉 [프로젝트 정리 웹페이지 보기](https://username.github.io/denoise_fpga_project)
