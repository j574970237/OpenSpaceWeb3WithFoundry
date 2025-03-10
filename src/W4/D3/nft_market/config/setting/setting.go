package setting

type DbConfig struct {
	DbType   string
	DbName   string
	Host     string
	Port     string
	Username string
	Pwd      string
	Sslmode  string
	TimeZone string
}
type BlockChainConfig struct {
	RpcUrl          string
	Address         string
	PrivateKey      string
	ContractAddress string
}
