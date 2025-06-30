/// Модель отзыва.
struct Review: Decodable {
    /// Аватар пользователя.
    let avatarUrl: String?
    /// Имя и фамилия пользователя.
    let firstName: String
    let lastName: String
    /// Рейтинг отзыва.
    let rating: Int
    /// Фотографии отзыва.
    let photoUrls: [String]?
    /// Текст отзыва.
    let text: String
    /// Время создания отзыва.
    let created: String
    
    enum CodingKeys: String, CodingKey {
        case avatarUrl = "avatar_url"
        case firstName = "first_name"
        case lastName = "last_name"
        case rating
        case photoUrls = "photo_urls"
        case text
        case created
    }
    
}
