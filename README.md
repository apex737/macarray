1. Aliasing 문제는 AREA를 더 써서 해결
- 인터페이스는 하나인데 경로는 2가지 -> MUX로 해결

2. 조합논리 블럭과 순차논리 블럭에서 동시 초기화는 금기
- OFF BY 1 문제는 next-current로 지연시켜서 해결

3. RSTN과 함께 쓰는 신호는 대량의 래치를 내면서 합성에 실패함
