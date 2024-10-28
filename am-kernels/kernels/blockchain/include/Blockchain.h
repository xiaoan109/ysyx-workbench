#ifndef BLOCKCHAIN_H
#define BLOCKCHAIN_H

#include "Block.h"

#define MAX_DIFFICULTY 9 //�Ѷ�ֵ����3��������������4���Կ�����࣬5��ԼҪ��2�������ҡ�
#define MAXBLOCK 10

class Blockchain {
public:
	Blockchain(int difficulty);//Ĭ�Ϲ��캯��
	void AddBlock(uint32_t nIndexIn, const char* sDataIn);//�������麯��
private:
  char _diffStr[MAX_DIFFICULTY + 3];
	Block _vChain[MAXBLOCK];//��������ı���
  int _nrBlock;
};
#endif
