export type ApiResponse<T> = {
  code: number;
  message: string;
  data: T;
  traceId?: string;
};

export type AdminDashboard = {
  activeVersion: string;
  categories: number;
  modules: number;
  points: number;
  publishedPoints: number;
  questions: number;
  publishedQuestions: number;
  lastSeedAt?: string;
};

export type KnowledgeCategory = {
  categoryId: string;
  code: string;
  title: string;
  description: string;
  totalPoints: number;
  completedPoints: number;
};

export type KnowledgePoint = {
  pointId: string;
  categoryId: string;
  moduleId: string;
  title: string;
  summary: string;
  tags: string[];
  difficulty: string;
  estimatedMinutes: number;
  completed: boolean;
  published: boolean;
  questionCount: number;
  sortOrder: number;
};

export type InterviewQuestion = {
  questionId: string;
  categoryId: string;
  pointId: string;
  type: string;
  title: string;
  prompt: string;
  answer: string;
  tags: string[];
  difficulty: string;
  frequency: string;
  published: boolean;
  sortOrder: number;
};

export type PointFormValues = {
  pointId?: string;
  categoryId: string;
  moduleId?: string;
  title: string;
  summary?: string;
  detail?: string;
  tags?: string[];
  difficulty?: string;
  estimatedMinutes?: number;
  published?: boolean;
  sortOrder?: number;
};

export type QuestionFormValues = {
  questionId?: string;
  categoryId: string;
  pointId?: string;
  title: string;
  prompt: string;
  answer?: string;
  tags?: string[];
  difficulty?: string;
  frequency?: string;
  published?: boolean;
  sortOrder?: number;
};

export type AdminLoginResult = {
  accessToken: string;
  admin: {
    id?: number;
    username: string;
    status?: string;
  };
};

export async function request<T>(
  baseUrl: string,
  token: string,
  path: string,
  init?: RequestInit,
): Promise<T> {
  const response = await fetch(`${trimSlash(baseUrl)}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...init?.headers,
    },
  });
  const payload = (await response.json()) as ApiResponse<T>;
  if (!response.ok || payload.code !== 200) {
    throw new Error(payload.message || `Request failed: ${response.status}`);
  }
  return payload.data;
}

export function adminApi(baseUrl: string, token: string) {
  return {
    login(username: string, password: string) {
      return request<AdminLoginResult>(baseUrl, '', '/api/admin/auth/login', {
        method: 'POST',
        body: JSON.stringify({ username, password }),
      });
    },
    dashboard() {
      return request<AdminDashboard>(
        baseUrl,
        token,
        '/api/admin/offer-hunter/dashboard',
      );
    },
    seedDefaultContent() {
      return request<{ version: string; points: number; questions: number }>(
        baseUrl,
        token,
        '/api/admin/offer-hunter/seed/default-content',
        { method: 'POST' },
      );
    },
    categories() {
      return request<KnowledgeCategory[]>(
        baseUrl,
        token,
        '/api/admin/offer-hunter/knowledge/categories',
      );
    },
    points(categoryId?: string) {
      const query = categoryId ? `?categoryId=${encodeURIComponent(categoryId)}` : '';
      return request<KnowledgePoint[]>(
        baseUrl,
        token,
        `/api/admin/offer-hunter/knowledge/points${query}`,
      );
    },
    upsertPoint(values: PointFormValues) {
      return request<unknown>(
        baseUrl,
        token,
        '/api/admin/offer-hunter/knowledge/points',
        { method: 'POST', body: JSON.stringify(values) },
      );
    },
    publishPoint(pointId: string, published: boolean) {
      return request<unknown>(
        baseUrl,
        token,
        `/api/admin/offer-hunter/knowledge/points/${encodeURIComponent(
          pointId,
        )}/publish?published=${published}`,
        { method: 'PUT' },
      );
    },
    questions(categoryId?: string, pointId?: string) {
      const params = new URLSearchParams();
      if (categoryId) params.set('categoryId', categoryId);
      if (pointId) params.set('pointId', pointId);
      const query = params.toString() ? `?${params.toString()}` : '';
      return request<InterviewQuestion[]>(
        baseUrl,
        token,
        `/api/admin/offer-hunter/questions${query}`,
      );
    },
    upsertQuestion(values: QuestionFormValues) {
      return request<unknown>(
        baseUrl,
        token,
        '/api/admin/offer-hunter/questions',
        { method: 'POST', body: JSON.stringify(values) },
      );
    },
    publishQuestion(questionId: string, published: boolean) {
      return request<unknown>(
        baseUrl,
        token,
        `/api/admin/offer-hunter/questions/${encodeURIComponent(
          questionId,
        )}/publish?published=${published}`,
        { method: 'PUT' },
      );
    },
  };
}

function trimSlash(value: string) {
  return value.replace(/\/$/, '');
}
