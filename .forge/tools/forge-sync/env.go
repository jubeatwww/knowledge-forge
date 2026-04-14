package main

import (
	"bufio"
	"os"
	"path/filepath"
	"strings"
)

func loadEnvFiles(vaultRoot string) error {
	protected := make(map[string]bool)
	for _, raw := range os.Environ() {
		key, _, ok := strings.Cut(raw, "=")
		if ok {
			protected[key] = true
		}
	}

	paths := []string{
		filepath.Join(vaultRoot, ".env"),
		filepath.Join(vaultRoot, ".forge", ".env"),
		filepath.Join(vaultRoot, ".forge", "forge-sync.env"),
	}

	for _, path := range paths {
		if err := loadEnvFile(path, protected); err != nil {
			return err
		}
	}
	return nil
}

func loadEnvFile(path string, protected map[string]bool) error {
	f, err := os.Open(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		if strings.HasPrefix(line, "export ") {
			line = strings.TrimSpace(strings.TrimPrefix(line, "export "))
		}

		key, value, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}

		key = strings.TrimSpace(key)
		if key == "" || protected[key] {
			continue
		}

		value = strings.TrimSpace(value)
		value = strings.Trim(value, `"'`)
		if err := os.Setenv(key, value); err != nil {
			return err
		}
	}

	return scanner.Err()
}
