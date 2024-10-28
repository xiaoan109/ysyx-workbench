#include <klib.h>
#include <klib-macros.h>
#include "Block.h"
#include "sha256.h"

void Block::block_init(uint32_t nIndexIn, const char *sDataIn, const char *sPrevHashIn) {
  _nIndex = nIndexIn;
  _sData = sDataIn;
  _sPrevHash = sPrevHashIn;
	_nNonce = -1;//Nounce����Ϊ-1
	_tTime = io_read(AM_TIMER_UPTIME).us / 1000000;//����ʱ��
}

const char* Block::GetHash() { //���ع�ϣֵ������ʵ��
	return _sHash;
}

void Block::MineBlock(const char *diffStr) { //�ڿ���������Ϊ�Ѷ�ֵ��
	int nDifficulty = strlen(diffStr);
	do {
		_nNonce++;
		_CalculateHash(_sHash);
	} while (memcmp(_sHash, diffStr, nDifficulty) != 0);
	//ҪѰ��һ��Nounceʹ�������ϣֵ��ǰnλ��0����0�ĸ��������Ѷ�ֵ�ĸ�����ͬ�����ڿ�ɹ���
	printf("Block mined:%s\n", _sHash);
}

inline void Block::_CalculateHash(char *buf) {
  static char str[1024];
  sprintf(str, "%d%d%s%d%s", _nIndex, _tTime, _sData, _nNonce, _sPrevHash);
  sha256(buf, str);
  sha256(buf, buf);
}
