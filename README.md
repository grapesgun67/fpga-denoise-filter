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
![Block Diagram](https://github.com/user-attachments/assets/b111c644-f8ca-4c44-9007-155283cf4288)
