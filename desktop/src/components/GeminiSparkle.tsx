import React from "react";

interface GeminiSparkleProps {
  size?: number;
  className?: string;
}

export function GeminiSparkle({ size = 32, className = "" }: GeminiSparkleProps) {
  const id = React.useId();
  const gradientId = `gemini-gradient-${id}`;

  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 32 32"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
      aria-label="Gemini"
    >
      <defs>
        <linearGradient id={gradientId} x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#4285F4" />
          <stop offset="50%" stopColor="#9B72CB" />
          <stop offset="100%" stopColor="#D96570" />
        </linearGradient>
      </defs>
      <path
        d="M16 2 C16 2, 17.5 10, 22 14 C26.5 18, 30 16, 30 16 C30 16, 22 17.5, 18 22 C14 26.5, 16 30, 16 30 C16 30, 14.5 22, 10 18 C5.5 14, 2 16, 2 16 C2 16, 10 14.5, 14 10 C18 5.5, 16 2, 16 2 Z"
        fill={`url(#${gradientId})`}
      />
    </svg>
  );
}
