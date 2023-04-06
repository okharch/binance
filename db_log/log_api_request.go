package db_log

import (
	"fmt"
	"github.com/jmoiron/sqlx"
	"time"
)

type ApiRequestLogRecord struct {
	//ID                 int64     `db:"id"` // no need for ID, it will be used just by LogApiRequest
	RequestUrl         string    `db:"request_url"`
	ComeTime           time.Time `db:"come_time"`
	RequestTime        time.Time `db:"request_time"`
	ResponseTime       time.Time `db:"response_time"`
	ResponseStatusCode int       `db:"response_status_code"`
	ResponseSize       int       `db:"response_size"`
	RetryAfter         int       `db:"retry_after"`
	UsedWeight         int       `db:"used_weight"`
}

func LogApiRequest(db *sqlx.DB, req ApiRequestLogRecord) error {
	_, err := db.NamedExec(`
		INSERT INTO binance_log.rest_api_requests (
			request_url, come_time, request_time, response_time,
			response_status_code, response_size, retry_after, used_weight
		) VALUES (
			:request_url, :come_time, :request_time, :response_time,
			:response_status_code, :response_size, :retry_after, :used_weight
		)`, req)
	if err != nil {
		return fmt.Errorf("failed to insert API request log: %v", err)
	}
	return nil
}
