package db

import (
	"fmt"
	"nftmarket/config/setting"
	"nftmarket/global"
	"nftmarket/internal/model"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var Db *gorm.DB

func NewDBEngine(dbConfig *setting.DbConfig) (*gorm.DB, error) {
	var err error
	conn := "host=%s user=%s password=%s dbname=%s port=%s sslmode=%s TimeZone=%s"
	dsn := fmt.Sprintf(conn, dbConfig.Host, dbConfig.Username, dbConfig.Pwd, dbConfig.DbName,
		dbConfig.Port, dbConfig.Sslmode, dbConfig.TimeZone)
	Db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info), // 打印sql语句
	})
	if err != nil {
		return nil, err
	}
	return Db, nil
}

// GetDB
func GetDB() *gorm.DB {
	return Db
}

// MigrateDb 初始化数据库表
func MigrateDb() error {
	if err := global.DBEngine.AutoMigrate(&model.Order{}); err != nil {
		return err
	}
	return nil
}
