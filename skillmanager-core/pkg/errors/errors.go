package errors

import "fmt"

type AppError struct {
	Code    string
	Message string
	Details map[string]any
	Cause   error
}

func (e *AppError) Error() string { return e.Message }
func (e *AppError) Unwrap() error { return e.Cause }

func New(code, msg string) *AppError {
	return &AppError{Code: code, Message: msg}
}

func Wrap(err error, code, msg string) *AppError {
	return &AppError{Code: code, Message: msg, Cause: err}
}

func (e *AppError) WithDetail(key string, val any) *AppError {
	if e.Details == nil {
		e.Details = map[string]any{}
	}
	e.Details[key] = val
	return e
}

func (e *AppError) JSON() map[string]any {
	return map[string]any{
		"error": map[string]any{
			"code":    e.Code,
			"message": e.Message,
			"details": e.Details,
		},
	}
}

// 错误码常量
const (
	CodeInvalidRequest        = "INVALID_REQUEST"
	CodeNotFound              = "NOT_FOUND"
	CodeDuplicateName         = "DUPLICATE_NAME"
	CodePathInvalid           = "PATH_INVALID"
	CodePathTraversal         = "PATH_TRAVERSAL"
	CodeSkillFormatIncompat   = "SKILL_FORMAT_INCOMPATIBLE"
	CodeMcpConnectionFailed   = "MCP_CONNECTION_FAILED"
	CodeMarketplaceRateLimit  = "MARKETPLACE_RATE_LIMITED"
	CodeNotImplemented        = "NOT_IMPLEMENTED"
	CodeInternal              = "INTERNAL_ERROR"
	CodeScanFailed            = "SCAN_FAILED"
)

func HTTPStatus(code string) int {
	switch code {
	case CodeInvalidRequest:
		return 400
	case CodeNotFound:
		return 404
	case CodeDuplicateName, CodeSkillFormatIncompat:
		return 409
	case CodePathInvalid, CodePathTraversal:
		return 422
	case CodeMcpConnectionFailed:
		return 423
	case CodeMarketplaceRateLimit:
		return 424
	case CodeNotImplemented:
		return 501
	case CodeScanFailed:
		return 503
	default:
		return 500
	}
}

func BadRequest(format string, args ...any) *AppError {
	return New(CodeInvalidRequest, fmt.Sprintf(format, args...))
}

func NotFound(format string, args ...any) *AppError {
	return New(CodeNotFound, fmt.Sprintf(format, args...))
}

func NotImplemented(feature string) *AppError {
	return &AppError{
		Code:    CodeNotImplemented,
		Message: "此功能将在后续版本提供",
		Details: map[string]any{"feature": feature, "plannedPhase": 3},
	}
}

func Internal(err error) *AppError {
	return Wrap(err, CodeInternal, "服务器内部错误")
}
