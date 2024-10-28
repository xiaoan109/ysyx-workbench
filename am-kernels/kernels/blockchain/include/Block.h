#ifndef BLOCK_H
#define BLOCK_H

#include <stdint.h>
#include "sha256.h"

//����������
class Block {
public:
  Block() { }
	void block_init(uint32_t nIndexIn, const char* sDataIn, const char* sPrevHashIn);
	const char* GetHash();//���ع�ϣֵ
	void MineBlock(const char* diffStr);//�ڿ�

private:
	uint32_t _nIndex;//��������ֵ���ڼ������飬��0��ʼ����
	uint32_t _nNonce;//���������
	const char *_sData;//���������ַ�
	char _sHash[2 * SHA256::DIGEST_SIZE + 1];//����Hashֵ
	const char *_sPrevHash;//ǰһ������Ĺ�ϣֵ
	uint32_t _tTime;//��������ʱ��
	void _CalculateHash(char *buf);//����Hashֵ
};
#endif
